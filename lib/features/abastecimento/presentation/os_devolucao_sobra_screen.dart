import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/os_detalhe_provider.dart';
import '../../../shared/utils/scanner_protection.dart';
import '../../../shared/widgets/autorizar_digitacao_dialog.dart';
import '../../../shared/providers/api_service_provider.dart';

/// Resultado da devolução de sobra
class DevolucaoSobraResult {
  final int codenderecoDevolucao;
  final String enderecoFormatado;
  final bool isOrigem;
  final bool confirmado;

  DevolucaoSobraResult({
    required this.codenderecoDevolucao,
    required this.enderecoFormatado,
    this.isOrigem = false,
    this.confirmado = true,
  });
}

/// Tela para bipagem do endereço de devolução da sobra.
/// Visual idêntico à tela de endereço (RUA/PRD/NVL/APT).
class OsDevolucaoSobraScreen extends ConsumerStatefulWidget {
  final int fase;
  final int numos;
  final int qtSobra;
  final int qtSolicitada;
  final int qtEstoqueOrigem;
  final String? enderecoOrigemFormatado;
  final int? codenderecoOrigem;
  final String? ruaOrigem;
  final int? predioOrigem;
  final int? nivelOrigem;
  final int? aptoOrigem;

  const OsDevolucaoSobraScreen({
    super.key,
    required this.fase,
    required this.numos,
    required this.qtSobra,
    required this.qtSolicitada,
    required this.qtEstoqueOrigem,
    this.enderecoOrigemFormatado,
    this.codenderecoOrigem,
    this.ruaOrigem,
    this.predioOrigem,
    this.nivelOrigem,
    this.aptoOrigem,
  });

  @override
  ConsumerState<OsDevolucaoSobraScreen> createState() =>
      _OsDevolucaoSobraScreenState();
}

class _OsDevolucaoSobraScreenState
    extends ConsumerState<OsDevolucaoSobraScreen> {
  final TextEditingController _enderecoController = TextEditingController();
  final FocusNode _enderecoFocusNode = FocusNode();
  bool _isProcessing = false;
  bool _tecladoLiberado = false;

  late final ScannerProtection _scannerProtection;

  @override
  void initState() {
    super.initState();
    _scannerProtection = ScannerProtection(
      onManualInputBlocked: () => _mostrarAvisoDigitacao(),
    );

    _enderecoFocusNode.addListener(_onFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enderecoFocusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    if (_enderecoFocusNode.hasFocus && !_tecladoLiberado) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  @override
  void dispose() {
    _enderecoController.dispose();
    _enderecoFocusNode.removeListener(_onFocusChange);
    _enderecoFocusNode.dispose();
    super.dispose();
  }

  void _mostrarAvisoDigitacao() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use o scanner ou solicite autorização para digitar'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Processa o código bipado/digitado
  Future<void> _processarBipagem(String codigo) async {
    final trimmed = codigo.trim();
    if (trimmed.isEmpty) return;
    _enderecoController.clear();

    if (!_tecladoLiberado) {
      final isScanner = _scannerProtection.checkInput(
        trimmed,
        tecladoLiberado: false,
        clearCallback: () => _enderecoController.clear(),
      );
      if (!isScanner) return;
    }

    await _validarEndereco(trimmed);
  }

  /// Valida endereço na API e aplica lógica de popups
  Future<void> _validarEndereco(String codigoEndereco) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final result = await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .validarEnderecoDevolucao(codigoEndereco);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.sucesso) {
      if (result.isOrigem) {
        // Endereço de origem — retorna direto sem popup
        Navigator.pop(
          context,
          DevolucaoSobraResult(
            codenderecoDevolucao: result.codendereco!,
            enderecoFormatado: result.enderecoFormatado ?? '',
            isOrigem: true,
            confirmado: true,
          ),
        );
      } else {
        // Endereço diferente e vazio — pede confirmação de transferência
        final confirmou = await _mostrarPopupConfirmacaoTransferencia(
          result.enderecoFormatado ?? codigoEndereco,
        );
        if (confirmou && mounted) {
          Navigator.pop(
            context,
            DevolucaoSobraResult(
              codenderecoDevolucao: result.codendereco!,
              enderecoFormatado: result.enderecoFormatado ?? '',
              isOrigem: false,
              confirmado: true,
            ),
          );
        } else if (mounted) {
          _enderecoFocusNode.requestFocus();
        }
      }
    } else {
      // Endereço inválido ou já contém estoque
      _mostrarErro(result.erro ?? 'Endereço inválido');
      _enderecoFocusNode.requestFocus();
    }
  }

  /// Popup de confirmação para transferência para endereço diferente
  Future<bool> _mostrarPopupConfirmacaoTransferencia(String endereco) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.swap_horiz_rounded,
          size: 40,
          color: Colors.orange,
        ),
        title: const Text(
          'Transferir sobra?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Este não é o endereço de origem.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Deseja transferir ${widget.qtSobra} UN para:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                endereco,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('SIM, TRANSFERIR'),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  /// Solicita autorização para digitação manual
  Future<void> _solicitarAutorizacaoDigitacao() async {
    FocusScope.of(context).unfocus();

    final resultado = await AutorizarDigitacaoDialog.mostrarComDados(
      context: context,
      apiService: ref.read(apiServiceProvider),
    );

    if (resultado.autorizado && mounted) {
      setState(() {
        _tecladoLiberado = true;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) _enderecoFocusNode.requestFocus();
    } else if (mounted) {
      _enderecoFocusNode.requestFocus();
    }
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Confirma bipagem via botão
  void _confirmarBipagem() {
    final codigo = _enderecoController.text.trim();
    if (codigo.isEmpty) {
      _mostrarErro('Bipe o código do endereço');
      return;
    }
    _scannerProtection.reset();
    _processarBipagem(codigo);
  }

  Widget _buildEnderecoBox(BuildContext context, String label, int value) {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temEndereco = widget.ruaOrigem != null &&
        widget.predioOrigem != null &&
        widget.nivelOrigem != null &&
        widget.aptoOrigem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('OS ${widget.numos} - Sobra'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              // Info da sobra - compacto
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.orange[800]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SOBRA DE PRODUTO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sobrou ${widget.qtSobra} UN — Bipe o endereço',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${widget.qtSobra}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Endereço de origem — visual RUA + PRD/NVL/APT
              if (temEndereco)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'DEVOLVER NO ENDEREÇO',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer
                              .withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // RUA badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'RUA ${widget.ruaOrigem}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // PRD / NVL / APT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildEnderecoBox(
                              context, 'PRD', widget.predioOrigem!),
                          const SizedBox(width: 6),
                          _buildEnderecoBox(
                              context, 'NVL', widget.nivelOrigem!),
                          const SizedBox(width: 6),
                          _buildEnderecoBox(
                              context, 'APT', widget.aptoOrigem!),
                        ],
                      ),
                    ],
                  ),
                )
              else if (widget.enderecoOrigemFormatado != null)
                // Fallback: endereço formatado em texto
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DEVOLVER NO ENDEREÇO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.enderecoOrigemFormatado!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Campo de bipar endereço
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _enderecoFocusNode.hasFocus
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: _enderecoFocusNode.hasFocus ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _enderecoController,
                        focusNode: _enderecoFocusNode,
                        enabled: !_isProcessing,
                        readOnly: false,
                        showCursor: true,
                        decoration: InputDecoration(
                          hintText: _tecladoLiberado
                              ? 'Digite o endereço...'
                              : 'Bipe o endereço',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: Icon(
                            _tecladoLiberado
                                ? Icons.keyboard
                                : Icons.qr_code_scanner,
                            size: 20,
                            color: _enderecoFocusNode.hasFocus
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                        keyboardType: _tecladoLiberado
                            ? TextInputType.text
                            : TextInputType.none,
                        onSubmitted: (_) {
                          _scannerProtection.reset();
                          _confirmarBipagem();
                        },
                        onChanged: (value) {
                          final permitido = _scannerProtection.checkInput(
                            value,
                            tecladoLiberado: _tecladoLiberado,
                            clearCallback: () {
                              _enderecoController.clear();
                              _scannerProtection.reset();
                            },
                          );

                          if (!permitido) return;

                          if (value.endsWith('\n') || value.endsWith('\r')) {
                            _enderecoController.text = value.trim();
                            _scannerProtection.reset();
                            _confirmarBipagem();
                          }
                        },
                      ),
                    ),
                    if (_isProcessing)
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Botões: Digitar | Confirmar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isProcessing ? null : _solicitarAutorizacaoDigitacao,
                      icon: const Icon(Icons.keyboard, size: 16),
                      label: const Text(
                        'DIGITAR',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isProcessing ? null : _confirmarBipagem,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'CONFIRMAR',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
