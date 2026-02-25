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
  final int qtEstoqueOrigem;
  final String? enderecoOrigemFormatado;
  final int? codenderecoOrigem;

  const OsDevolucaoSobraScreen({
    super.key,
    required this.fase,
    required this.numos,
    required this.qtSobra,
    required this.qtSolicitada,
    required this.qtEstoqueOrigem,
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
      // Válido — retorna direto sem precisar de botão
      Navigator.pop(
        context,
        DevolucaoSobraResult(
          codenderecoDevolucao: result.codendereco!,
          enderecoFormatado: result.enderecoFormatado ?? '',
          isOrigem: result.isOrigem,
          confirmado: true,
        ),
      );
    } else {
      _mostrarErro(result.erro ?? 'Endereço inválido');
      _enderecoFocusNode.requestFocus();
    }
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
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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

  void _mostrarDialogDivergencia() {
    final observacaoController = TextEditingController();
    String? tipoSelecionado;

    final tiposDivergencia = [
      {'value': 'quantidade_menor', 'label': 'Quantidade Menor'},
      {'value': 'quantidade_maior', 'label': 'Quantidade Maior'},
      {'value': 'produto_errado', 'label': 'Produto Errado'},
      {'value': 'nao_encontrado', 'label': 'Não Encontrado'},
      {'value': 'outro', 'label': 'Outro (especificar)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isOutro = tipoSelecionado == 'outro';

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Icon(Icons.warning_amber_rounded,
                        size: 32, color: Colors.orange),
                    const SizedBox(height: 8),

                    const Text(
                      'Sinalizar Divergência',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: tipoSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Tipo da divergência *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: tiposDivergencia.map((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo['value'] as String,
                          child: Text(tipo['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          tipoSelecionado = value;
                          if (value != 'outro') {
                            observacaoController.clear();
                          }
                        });
                      },
                    ),

                    if (isOutro) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: observacaoController,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Descreva a divergência *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (tipoSelecionado == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Selecione o tipo'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              final observacao =
                                  observacaoController.text.trim();

                              if (tipoSelecionado == 'outro' &&
                                  observacao.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Descreva a divergência'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              Navigator.of(ctx).pop();
                              final (sucesso, erro) = await ref
                                  .read(
                                    osDetalheNotifierProvider(
                                      widget.fase,
                                      widget.numos,
                                    ).notifier,
                                  )
                                  .sinalizarDivergencia(
                                    tipoSelecionado!,
                                    observacao.isNotEmpty
                                        ? observacao
                                        : null,
                                  );
                              if (sucesso && mounted) {
                                _mostrarSucesso('Divergência sinalizada!');
                              } else if (mounted) {
                                _mostrarErro(
                                    erro ?? 'Erro ao sinalizar');
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Confirmar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.orange[800]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.white, size: 24),
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
                            'Sobrou ${widget.qtSobra} UN — Bipe onde devolver',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

              const SizedBox(height: 10),

              // Campo de bipagem
              TextField(
                controller: _enderecoController,
                focusNode: _enderecoFocusNode,
                keyboardType:
                    _tecladoLiberado ? TextInputType.text : TextInputType.none,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Bipe o endereço de devolução',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.qr_code_scanner, color: Colors.orange),
                  suffixIcon: !_tecladoLiberado
                      ? IconButton(
                          icon: const Icon(Icons.keyboard, size: 20),
                          tooltip: 'Digitar manualmente',
                          onPressed: _solicitarAutorizacaoDigitacao,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (v) => _processarBipagem(v),
              ),

              if (_isProcessing) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(color: Colors.orange),
              ],

              const Spacer(),

              // Botão de divergência
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () => _mostrarDialogDivergencia(),
                  icon: const Icon(Icons.warning_amber, size: 18),
                  label: const Text(
                    'SINALIZAR DIVERGÊNCIA',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
