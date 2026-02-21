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

/// Tela para bipagem do endereço de devolução da sobra
class OsDevolucaoSobraScreen extends ConsumerStatefulWidget {
  final int fase;
  final int numos;
  final int qtSobra;
  final int qtSolicitada;
  final int qtRetirada;
  final String? enderecoOrigemFormatado;
  final int? codenderecoOrigem;

  const OsDevolucaoSobraScreen({
    super.key,
    required this.fase,
    required this.numos,
    required this.qtSobra,
    required this.qtSolicitada,
    required this.qtRetirada,
    this.enderecoOrigemFormatado,
    this.codenderecoOrigem,
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
  int? _autorizadorMatricula;

  // Endereço validado
  int? _codenderecoValidado;
  String? _enderecoFormatadoValidado;
  bool _isOrigem = false;

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

  /// Valida endereço na API
  Future<void> _validarEndereco(String codigoEndereco) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final result = await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .validarEnderecoDevolucao(codigoEndereco);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.sucesso) {
      setState(() {
        _codenderecoValidado = result.codendereco;
        _enderecoFormatadoValidado = result.enderecoFormatado;
        _isOrigem = result.isOrigem;
      });

      _mostrarSucesso(
        result.isOrigem
            ? 'Endereço de origem confirmado!'
            : 'Endereço ${result.enderecoFormatado} validado!',
      );
    } else {
      _mostrarErro(result.erro ?? 'Endereço inválido');
      _enderecoFocusNode.requestFocus();
    }
  }

  /// Confirma devolução e retorna resultado
  void _confirmar() {
    if (_codenderecoValidado == null) return;

    Navigator.pop(
      context,
      DevolucaoSobraResult(
        codenderecoDevolucao: _codenderecoValidado!,
        enderecoFormatado: _enderecoFormatadoValidado ?? '',
        isOrigem: _isOrigem,
        confirmado: true,
      ),
    );
  }

  /// Atalho para devolver para o endereço de origem sem bipar
  void _devolverParaOrigem() {
    if (widget.codenderecoOrigem == null) return;

    Navigator.pop(
      context,
      DevolucaoSobraResult(
        codenderecoDevolucao: widget.codenderecoOrigem!,
        enderecoFormatado: widget.enderecoOrigemFormatado ?? '',
        isOrigem: true,
        confirmado: true,
      ),
    );
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
        _autorizadorMatricula = resultado.matriculaAutorizador;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) _enderecoFocusNode.requestFocus();
    } else if (mounted) {
      _enderecoFocusNode.requestFocus();
    }
  }

  void _mostrarSucesso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Info da sobra
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.orange[800]!],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'SOBRA DE PRODUTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoCol(
                              'Solicitado', '${widget.qtSolicitada}'),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.white30,
                          ),
                          _buildInfoCol('Retirado', '${widget.qtRetirada}'),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.white30,
                          ),
                          _buildInfoCol(
                            'Sobra',
                            '+${widget.qtSobra}',
                            destaque: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bipe o endereço onde vai devolver a sobra',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Botão rápido: devolver para origem
              if (widget.codenderecoOrigem != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _codenderecoValidado == null ? _devolverParaOrigem : null,
                    icon: const Icon(Icons.undo, size: 16),
                    label: Text(
                      'DEVOLVER P/ ORIGEM (${widget.enderecoOrigemFormatado ?? ''})',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),

              if (widget.codenderecoOrigem != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'ou bipe outro endereço:',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ),

              // Campo de bipagem
              TextField(
                controller: _enderecoController,
                focusNode: _enderecoFocusNode,
                keyboardType:
                    _tecladoLiberado ? TextInputType.text : TextInputType.none,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Bipe o endereço',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.qr_code_scanner, color: Colors.orange),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_tecladoLiberado)
                        IconButton(
                          icon: const Icon(Icons.keyboard, size: 20),
                          tooltip: 'Digitar manualmente',
                          onPressed: _solicitarAutorizacaoDigitacao,
                        ),
                      if (_enderecoController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.orange),
                          onPressed: () => _processarBipagem(
                              _enderecoController.text),
                        ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (v) => _processarBipagem(v),
              ),

              if (_isProcessing) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(color: Colors.orange),
              ],

              // Endereço validado
              if (_codenderecoValidado != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[700], size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _enderecoFormatadoValidado ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            Text(
                              _isOrigem
                                  ? 'Endereço de origem'
                                  : 'Outro endereço',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botão para trocar
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _codenderecoValidado = null;
                            _enderecoFormatadoValidado = null;
                            _isOrigem = false;
                          });
                          _enderecoFocusNode.requestFocus();
                        },
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Trocar endereço',
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Botão confirmar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed:
                      _codenderecoValidado != null ? _confirmar : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _codenderecoValidado != null
                            ? Icons.check_circle
                            : Icons.block,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _codenderecoValidado != null
                            ? 'CONFIRMAR DEVOLUÇÃO (${widget.qtSobra} UN)'
                            : 'BIPE O ENDEREÇO PRIMEIRO',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value, {bool destaque = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: destaque ? 18 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
