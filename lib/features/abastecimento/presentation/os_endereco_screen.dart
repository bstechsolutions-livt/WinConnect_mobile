import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/os_detalhe_provider.dart';
import '../../../shared/models/os_detalhe_model.dart';
import '../../../shared/providers/api_service_provider.dart';
import '../../../shared/widgets/autorizar_digitacao_dialog.dart';
import 'os_bipar_screen.dart';

/// Tela de Endereço Origem
/// Mostra o endereço onde o operador deve ir e pede para bipar o código do endereço
class OsEnderecoScreen extends ConsumerStatefulWidget {
  final int fase;
  final int numos;
  final String faseNome;

  const OsEnderecoScreen({
    super.key,
    required this.fase,
    required this.numos,
    required this.faseNome,
  });

  @override
  ConsumerState<OsEnderecoScreen> createState() => _OsEnderecoScreenState();
}

class _OsEnderecoScreenState extends ConsumerState<OsEnderecoScreen> {
  final _enderecoController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isProcessing = false;
  bool _tecladoLiberado =
      false; // Flag para controlar se digitação foi autorizada

  @override
  void initState() {
    super.initState();
    // Escuta input do scanner físico (funciona como teclado)
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Esconde o teclado virtual mas mantém o foco para o scanner
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_tecladoLiberado) {
      // Quando ganha foco, esconde o teclado (a menos que esteja liberado)
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _enderecoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Abre scanner de câmera
  void _abrirScannerCamera(OsDetalhe os) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Escanear Endereço',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Scanner
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: MobileScannerController(
                    facing: CameraFacing.back, // Câmera traseira no celular
                  ),
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty &&
                        barcodes.first.rawValue != null) {
                      final codigo = barcodes.first.rawValue!;
                      Navigator.pop(context);
                      _enderecoController.text = codigo;
                      _confirmarEndereco(os);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aponte a câmera para o código de barras do endereço',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Solicita autorização do supervisor para digitar manualmente
  Future<void> _solicitarAutorizacaoDigitar() async {
    final autorizado = await AutorizarDigitacaoDialog.mostrar(
      context: context,
      apiService: ref.read(apiServiceProvider),
    );

    if (autorizado && mounted) {
      setState(() {
        _tecladoLiberado = true;
      });
      // Aguarda um frame para garantir que o estado foi atualizado
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _focusNode.requestFocus();
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(
      osDetalheNotifierProvider(widget.fase, widget.numos),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('OS ${widget.numos}'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Não mostra seta de voltar
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            tooltip: 'Sair da OS',
            onPressed: () => _mostrarDialogSairOs(context),
          ),
        ],
      ),
      body: osAsync.when(
        data: (os) => _buildContent(context, os),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar OS',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(
                        osDetalheNotifierProvider(
                          widget.fase,
                          widget.numos,
                        ).notifier,
                      )
                      .refresh(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, OsDetalhe os) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              // Nome do produto (compacto, só pra identificar)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  os.descricao,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              // Endereço: RUA + PRÉDIO.NÍVEL.APTO com labels
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
                      'VÁ ATÉ O ENDEREÇO',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // RUA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'RUA ${os.enderecoOrigem.rua}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Prédio, Nível, Apto em caixas com labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildEnderecoBox(context, 'PRD', os.enderecoOrigem.predio),
                        const SizedBox(width: 6),
                        _buildEnderecoBox(context, 'NVL', os.enderecoOrigem.nivel),
                        const SizedBox(width: 6),
                        _buildEnderecoBox(context, 'APT', os.enderecoOrigem.apto),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Campo de bipar endereço (área principal de ação)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: _focusNode.hasFocus ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _enderecoController,
                        focusNode: _focusNode,
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
                            color: _focusNode.hasFocus
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
                        onSubmitted: (_) => _confirmarEndereco(os),
                        onChanged: (value) {
                          if (value.endsWith('\n') || value.endsWith('\r')) {
                            _enderecoController.text = value.trim();
                            _confirmarEndereco(os);
                          }
                        },
                      ),
                    ),
                    if (!_isProcessing)
                      IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        tooltip: 'Câmera',
                        onPressed: () => _abrirScannerCamera(os),
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
                      onPressed: _isProcessing
                          ? null
                          : () => _solicitarAutorizacaoDigitar(),
                      icon: const Icon(Icons.keyboard, size: 16),
                      label: const Text('DIGITAR', style: TextStyle(fontSize: 11)),
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
                      onPressed: _isProcessing
                          ? null
                          : () => _confirmarEndereco(os),
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

              const SizedBox(height: 8),

              // Informações adicionais (colapsadas, menos destaque)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip('Cód', os.codprod.toString()),
                    _buildInfoChip('Estoque', os.qtEstoqueAtual.toStringAsFixed(0)),
                    _buildInfoChip('Múltiplo', os.multiplo.toString()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 8,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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

  Future<void> _confirmarEndereco(OsDetalhe os) async {
    final codigo = _enderecoController.text.trim();

    if (codigo.isEmpty) {
      _mostrarErro('Bipe o código do endereço');
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    // Chama bipar-endereco
    final (sucesso, erro) = await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .biparEndereco(codigo);

    if (!sucesso) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _mostrarErro(erro ?? 'Endereço incorreto');
      _enderecoController.clear();
      _focusNode.requestFocus();
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Sucesso! Navega para tela de bipar produto
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => OsBiparScreen(
          fase: widget.fase,
          numos: widget.numos,
          faseNome: widget.faseNome,
        ),
      ),
    );

    // Se retornou resultado (bloqueou ou finalizou), propaga para a tela anterior
    if (resultado == true && mounted) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(true);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarDialogSairOs(BuildContext context) {
    final matriculaController = TextEditingController();
    final senhaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.exit_to_app,
                          color: Colors.red.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SAIR DA OS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Autorização necessária',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Aviso
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Para sair desta OS é necessária autorização de um supervisor.',
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Campo matrícula
                  TextFormField(
                    controller: matriculaController,
                    decoration: InputDecoration(
                      labelText: 'Matrícula do Supervisor',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a matrícula';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Campo senha
                  TextFormField(
                    controller: senhaController,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a senha';
                      }
                      return null;
                    },
                  ),

                  // Erro
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('CANCELAR'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;

                                  setSheetState(() {
                                    isLoading = true;
                                    errorMessage = null;
                                  });

                                  try {
                                    final (sucesso, erro) = await ref
                                        .read(
                                          osDetalheNotifierProvider(
                                            widget.fase,
                                            widget.numos,
                                          ).notifier,
                                        )
                                        .sairDaOs(
                                          int.parse(matriculaController.text),
                                          senhaController.text,
                                        );

                                    if (sucesso) {
                                      if (sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                      }
                                      if (mounted) {
                                        Navigator.of(
                                          context,
                                        ).popUntil((route) => route.isFirst);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Saída da OS autorizada com sucesso',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } else {
                                      setSheetState(() {
                                        isLoading = false;
                                        errorMessage =
                                            erro?.replaceAll(
                                              'Exception: ',
                                              '',
                                            ) ??
                                            'Erro ao sair da OS';
                                      });
                                    }
                                  } catch (e) {
                                    setSheetState(() {
                                      isLoading = false;
                                      errorMessage = e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      );
                                    });
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'SAIR DA OS',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
