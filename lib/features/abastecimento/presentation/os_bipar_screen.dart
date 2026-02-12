import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/os_detalhe_provider.dart';
import '../../../shared/models/os_detalhe_model.dart';
import '../../../shared/models/finalizacao_result_model.dart';
import '../../../shared/providers/api_service_provider.dart';
import '../../../shared/utils/scanner_protection.dart';
import '../../../shared/widgets/autorizar_digitacao_dialog.dart';
import 'os_endereco_screen.dart';
import 'os_conferencia_quantidade_screen.dart';

/// 6ª TELA - Detalhes da OS após chegar no endereço
class OsBiparScreen extends ConsumerStatefulWidget {
  final int fase;
  final int numos;
  final String faseNome;

  const OsBiparScreen({
    super.key,
    required this.fase,
    required this.numos,
    required this.faseNome,
  });

  @override
  ConsumerState<OsBiparScreen> createState() => _OsBiparScreenState();
}

class _OsBiparScreenState extends ConsumerState<OsBiparScreen> {
  final TextEditingController _eanController = TextEditingController();
  final TextEditingController _unitizadorController = TextEditingController();
  final FocusNode _eanFocusNode = FocusNode();
  final FocusNode _unitizadorFocusNode = FocusNode();
  bool _isProcessing = false;
  bool _finalizacaoIniciada = false; // Evita chamar finalização múltiplas vezes

  // Flags de teclado liberado (por campo)
  bool _tecladoLiberadoEan = false;
  bool _tecladoLiberadoUnitizador = false;

  // Dados de autorização para rastreabilidade (digitado vs escaneado)
  int? _autorizadorMatriculaEan;
  int? _autorizadorMatriculaUnitizador;

  // Proteção contra digitação manual
  late final ScannerProtection _scannerProtectionEan;
  late final ScannerProtection _scannerProtectionUnitizador;

  // Cache da quantidade conferida (usado após vincular unitizador)
  int? _caixasConferidas;
  int? _unidadesConferidas;
  int? _qtConferida;

  @override
  void initState() {
    super.initState();

    // Inicializa proteção contra digitação manual
    _scannerProtectionEan = ScannerProtection(
      onManualInputBlocked: () => _mostrarAvisoDigitacao(),
    );
    _scannerProtectionUnitizador = ScannerProtection(
      onManualInputBlocked: () => _mostrarAvisoDigitacao(),
    );

    // Esconde teclado quando foca (para scanner físico)
    _eanFocusNode.addListener(_onEanFocusChange);
    _unitizadorFocusNode.addListener(_onUnitizadorFocusChange);

    // Foca no campo após build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _eanFocusNode.requestFocus();
    });
  }

  void _onEanFocusChange() {
    if (_eanFocusNode.hasFocus && !_tecladoLiberadoEan) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  void _onUnitizadorFocusChange() {
    if (_unitizadorFocusNode.hasFocus && !_tecladoLiberadoUnitizador) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
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

  /// Formata a quantidade separada mostrando caixas e/ou unidades
  String _formatarQuantidadeSeparada() {
    final caixas = _caixasConferidas ?? 0;
    final unidades = _unidadesConferidas ?? 0;

    if (caixas > 0 && unidades > 0) {
      return 'SEPARADO: $caixas CX + $unidades UN';
    } else if (caixas > 0) {
      return 'SEPARADO: $caixas CX';
    } else if (unidades > 0) {
      return 'SEPARADO: $unidades UN';
    } else {
      return 'SEPARADO: 0 UN';
    }
  }

  @override
  void dispose() {
    _scannerProtectionEan.dispose();
    _scannerProtectionUnitizador.dispose();
    _eanFocusNode.removeListener(_onEanFocusChange);
    _unitizadorFocusNode.removeListener(_onUnitizadorFocusChange);
    _eanController.dispose();
    _unitizadorController.dispose();
    _eanFocusNode.dispose();
    _unitizadorFocusNode.dispose();
    super.dispose();
  }

  /// Solicita autorização do supervisor para digitar manualmente
  Future<void> _solicitarAutorizacaoDigitar(FocusNode focusNode) async {
    // Remove foco antes de abrir o dialog para evitar conflitos no Flutter Web
    FocusScope.of(context).unfocus();

    final resultado = await AutorizarDigitacaoDialog.mostrarComDados(
      context: context,
      apiService: ref.read(apiServiceProvider),
    );

    if (resultado.autorizado && mounted) {
      // Define qual campo foi liberado e armazena matrícula do autorizador
      if (focusNode == _eanFocusNode) {
        setState(() {
          _tecladoLiberadoEan = true;
          _autorizadorMatriculaEan = resultado.matriculaAutorizador;
        });
      } else if (focusNode == _unitizadorFocusNode) {
        setState(() {
          _tecladoLiberadoUnitizador = true;
          _autorizadorMatriculaUnitizador = resultado.matriculaAutorizador;
        });
      }
      // Pequeno delay para o Flutter Web processar a mudança de estado
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        focusNode.requestFocus();
      }
    }
  }

  /// Abre scanner de câmera para EAN
  void _abrirScannerCameraEan(OsDetalhe os) {
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
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Escanear Código do Produto',
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
                    facing: CameraFacing.back,
                  ),
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty &&
                        barcodes.first.rawValue != null) {
                      final codigo = barcodes.first.rawValue!;
                      Navigator.pop(context);
                      _eanController.text = codigo;
                      _biparProduto(os);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aponte a câmera para o código de barras do produto',
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

  /// Abre scanner de câmera para Unitizador
  void _abrirScannerCameraUnitizador(OsDetalhe os) {
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
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Escanear Etiqueta do Unitizador',
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
                    facing: CameraFacing.back,
                  ),
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty &&
                        barcodes.first.rawValue != null) {
                      final codigo = barcodes.first.rawValue!;
                      Navigator.pop(context);
                      _unitizadorController.text = codigo;
                      _vincularUnitizador(os);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aponte a câmera para a etiqueta do palete/unitizador',
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

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(
      osDetalheNotifierProvider(widget.fase, widget.numos),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('OS ${widget.numos}'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove botão voltar
        actions: [
          // Botão Sair da OS
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.red.shade400),
            tooltip: 'Sair da OS',
            onPressed: () => _mostrarDialogSairOs(context),
          ),
        ],
      ),
      body: osAsync.when(
        data: (os) => _buildContent(context, os),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(error.toString(), textAlign: TextAlign.center),
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
    );
  }

  Widget _buildContent(BuildContext context, OsDetalhe os) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            // Botões de ação (esconde quando já bipou o produto)
            if (!os.produtoBipado) ...[
              Row(
                children: [
                  _buildActionButton(
                    context,
                    'BLOQUEAR',
                    Colors.red,
                    () => _mostrarDialogBloquear(context),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    'DIVERGÊNCIA',
                    Colors.orange,
                    () => _mostrarDialogDivergencia(context),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    'ESTOQUES',
                    Colors.blue,
                    () => _mostrarEstoques(context, os.codprod, os.descricao),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Título dinâmico
            Text(
              os.produtoBipado ? 'BIPAR UNITIZADOR' : 'BIPAR PRODUTO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),

            // Card: Produto com destaque (mostra confirmado quando já bipou)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: os.produtoBipado
                      ? Colors.green.withValues(alpha: 0.5)
                      : Colors.orange.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Mostra badge de confirmado no card
                  if (os.produtoBipado) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatarQuantidadeSeparada(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    os.descricao,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: os.produtoBipado ? 14 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Badges: código, múltiplo e estoque do endereço origem
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CÓD: ${os.codprod}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      // Só mostra o múltiplo e estoque quando ainda não bipou o produto
                      if (!os.produtoBipado) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '1 CX = ${os.multiplo} UN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        // Estoque no endereço de origem
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'EST: ${os.qtEstoqueAtual.toInt()} UN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Campo de bipagem ou status
            if (!os.produtoBipado) ...[
              _buildScannerInput(
                context: context,
                controller: _eanController,
                focusNode: _eanFocusNode,
                hintText: 'Bipar Produto',
                icon: Icons.qr_code_scanner,
                onCameraPressed: () => _abrirScannerCameraEan(os),
                onDigitarPressed: () =>
                    _solicitarAutorizacaoDigitar(_eanFocusNode),
                onConfirmarPressed: () => _biparProduto(os),
                onSubmitted: (_) {
                  _scannerProtectionEan.reset();
                  _biparProduto(os);
                },
                onChanged: (value) {
                  // Verifica se é digitação manual não autorizada
                  final permitido = _scannerProtectionEan.checkInput(
                    value,
                    tecladoLiberado: _tecladoLiberadoEan,
                    clearCallback: () {
                      _eanController.clear();
                      _scannerProtectionEan.reset();
                    },
                  );

                  if (!permitido) return;

                  if (value.endsWith('\n') || value.endsWith('\r')) {
                    _eanController.text = value.trim();
                    _scannerProtectionEan.reset();
                    _biparProduto(os);
                  }
                },
                tecladoLiberado: _tecladoLiberadoEan,
              ),
            ] else if (!os.unitizadorVinculado) ...[
              // Scanner para unitizador (sem a caixinha separada de confirmado)
              _buildScannerInput(
                context: context,
                controller: _unitizadorController,
                focusNode: _unitizadorFocusNode,
                hintText: 'Bipe o unitizador...',
                icon: Icons.local_shipping,
                onCameraPressed: () => _abrirScannerCameraUnitizador(os),
                onDigitarPressed: () =>
                    _solicitarAutorizacaoDigitar(_unitizadorFocusNode),
                onConfirmarPressed: () => _vincularUnitizador(os),
                onSubmitted: (_) {
                  _scannerProtectionUnitizador.reset();
                  _vincularUnitizador(os);
                },
                onChanged: (value) {
                  // Verifica se é digitação manual não autorizada
                  final permitido = _scannerProtectionUnitizador.checkInput(
                    value,
                    tecladoLiberado: _tecladoLiberadoUnitizador,
                    clearCallback: () {
                      _unitizadorController.clear();
                      _scannerProtectionUnitizador.reset();
                    },
                  );

                  if (!permitido) return;

                  if (value.endsWith('\n') || value.endsWith('\r')) {
                    _unitizadorController.text = value.trim();
                    _scannerProtectionUnitizador.reset();
                    _vincularUnitizador(os);
                  }
                },
                tecladoLiberado: _tecladoLiberadoUnitizador,
              ),
            ] else ...[
              // Unitizador já vinculado - finalizar automaticamente
              // Mostra indicador de processamento enquanto finaliza
              Builder(
                builder: (context) {
                  // Agenda a finalização automática após o build (apenas uma vez)
                  if (!_isProcessing && !_finalizacaoIniciada) {
                    _finalizacaoIniciada = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _finalizarOs(os);
                      }
                    });
                  }
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'PRODUTO ✓',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.local_shipping,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'UNITIZADOR: ${os.codunitizador}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Finalizando tarefa...',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Widget reutilizável para scanner input
  Widget _buildScannerInput({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    required VoidCallback onCameraPressed,
    required VoidCallback onDigitarPressed,
    required VoidCallback onConfirmarPressed,
    required Function(String) onSubmitted,
    required Function(String) onChanged,
    bool tecladoLiberado = false,
  }) {
    return Column(
      children: [
        // Campo de input
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: focusNode.hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !_isProcessing,
                  readOnly: false,
                  showCursor: true,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(fontSize: 14),
                    prefixIcon: Icon(
                      icon,
                      size: 20,
                      color: focusNode.hasFocus
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: tecladoLiberado
                      ? TextInputType.text
                      : TextInputType.none,
                  onSubmitted: onSubmitted,
                  onChanged: onChanged,
                ),
              ),
              if (!_isProcessing)
                IconButton(
                  icon: const Icon(Icons.camera_alt, size: 20),
                  tooltip: 'Escanear com câmera',
                  onPressed: onCameraPressed,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Use o leitor de código de barras ou toque na câmera',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : onDigitarPressed,
                icon: const Icon(Icons.keyboard, color: Colors.orange, size: 18),
                label: const Text('DIGITAR', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isProcessing ? null : onConfirmarPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'CONFIRMAR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnderecoBox(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.7),
              fontSize: 7,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Cache do tipo bipado (caixa ou unidade)
  String? _tipoBipado;

  Future<void> _biparProduto(OsDetalhe os) async {
    final ean = _eanController.text.trim();
    if (ean.isEmpty) {
      _mostrarErro('Bipe o código do produto');
      return;
    }

    // Primeiro valida o código de barras na API
    if (!mounted) return;
    setState(() => _isProcessing = true);

    // Envia info de digitação para rastreabilidade
    final result = await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .biparProdutoComTipo(
          ean,
          digitado: _tecladoLiberadoEan,
          autorizadorMatricula: _autorizadorMatriculaEan,
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Reseta flag de teclado após usar (só vale para uma bipagem)
    if (_tecladoLiberadoEan) {
      setState(() {
        _tecladoLiberadoEan = false;
        _autorizadorMatriculaEan = null;
      });
    }

    if (result.sucesso) {
      // Guarda o tipo bipado para uso posterior
      _tipoBipado = result.tipo;

      // Produto válido, abre tela para conferência de quantidade
      // Se bipou CAIXA, inicia com 1 CX, se bipou UNIDADE, inicia com 1 UN
      final caixasIniciais = result.isCaixa ? 1 : 0;
      final unidadesIniciais = result.isUnidade ? 1 : 0;

      _mostrarConferenciaQuantidadeComValores(
        ean,
        os,
        caixasIniciais,
        unidadesIniciais,
        tipoBipado: result.tipo,
      );
    } else {
      _mostrarErro(result.erro ?? 'Código de barras inválido!');
    }
  }

  /// Mostra tela para conferência de quantidade
  void _mostrarConferenciaQuantidade(String codigoBarras, OsDetalhe os) {
    _mostrarConferenciaQuantidadeComValores(codigoBarras, os, 0, 0);
  }

  /// Mostra tela para conferência de quantidade COM valores iniciais
  Future<void> _mostrarConferenciaQuantidadeComValores(
    String codigoBarras,
    OsDetalhe os,
    int caixasIniciais,
    int unidadesIniciais, {
    String? tipoBipado,
  }) async {
    final result = await Navigator.push<ConferenciaQuantidadeResult>(
      context,
      MaterialPageRoute(
        builder: (context) => OsConferenciaQuantidadeScreen(
          numos: os.numos,
          codprod: os.codprod,
          descricao: os.descricao,
          multiplo: os.multiplo,
          qtSolicitada: os.qtSolicitada.toInt(),
          caixasIniciais: caixasIniciais,
          unidadesIniciais: unidadesIniciais,
          tipoBipado: tipoBipado,
        ),
      ),
    );

    // Se o usuário confirmou a quantidade
    if (result != null && result.confirmado && mounted) {
      await _confirmarBipagem(codigoBarras, os, result.caixas, result.unidades);
    }
  }

  /// Confirma a bipagem e guarda quantidade em cache (não finaliza ainda!)
  /// A finalização só acontece após vincular o unitizador
  Future<void> _confirmarBipagem(
    String codigoBarras,
    OsDetalhe os,
    int caixas,
    int unidades,
  ) async {
    // Calcula quantidade total
    final qtConferida = (caixas * os.multiplo) + unidades;

    // Guarda em cache para usar depois de vincular unitizador
    if (!mounted) return;
    setState(() {
      _caixasConferidas = caixas;
      _unidadesConferidas = unidades;
      _qtConferida = qtConferida;
    });

    // Marca produto como bipado no provider (atualiza estado local)
    await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .marcarProdutoBipado();

    _mostrarSucesso('Quantidade conferida: $qtConferida UN');

    // Força rebuild e foca no campo de unitizador
    if (mounted) {
      setState(() {}); // Força rebuild após atualização do provider
      // Aguarda um frame para garantir que o campo de unitizador existe
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _unitizadorFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _vincularUnitizador(OsDetalhe os) async {
    // Evita chamadas duplicadas
    if (_isProcessing) return;

    final codigo = _unitizadorController.text.trim();
    if (codigo.isEmpty) {
      if (mounted) _mostrarErro('Bipe a etiqueta do unitizador');
      return;
    }

    // Verifica se tem os dados de conferência antes de prosseguir
    if (_qtConferida == null ||
        _caixasConferidas == null ||
        _unidadesConferidas == null) {
      if (mounted) {
        _mostrarErro(
          'Erro: quantidade não conferida. Bipe o produto novamente.',
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    // Chama o método que faz tudo junto: vincula + finaliza (com resultado detalhado)
    final result = await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .vincularUnitizadorEFinalizarComResult(
          codigoBarrasUnitizador: codigo,
          qtConferida: _qtConferida!,
          caixas: _caixasConferidas!,
          unidades: _unidadesConferidas!,
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.sucesso) {
      _unitizadorController.clear();
      // Processa resultado da finalização (próxima OS ou rua finalizada)
      await _processarResultadoFinalizacao(result);
    } else {
      // Verifica se precisa registrar divergência
      if (result.deveRegistrarDivergencia) {
        _mostrarDialogDivergenciaObrigatoria();
      } else {
        _mostrarErro(result.erro ?? 'Erro ao finalizar');
      }
    }
  }

  Future<void> _finalizarOs(OsDetalhe os) async {
    // Usa os dados em cache da conferência de quantidade
    if (_qtConferida == null ||
        _caixasConferidas == null ||
        _unidadesConferidas == null) {
      _mostrarErro('Erro: quantidade não conferida');
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    // Finaliza com quantidade normal (com resultado detalhado)
    final result = await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .finalizarComQuantidadeResult(
          _qtConferida!,
          _caixasConferidas!,
          _unidadesConferidas!,
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.sucesso) {
      // Processa resultado da finalização (próxima OS ou rua finalizada)
      await _processarResultadoFinalizacao(result);
    } else {
      // Verifica se precisa registrar divergência
      if (result.deveRegistrarDivergencia) {
        _mostrarDialogDivergenciaObrigatoria();
      } else {
        _mostrarErro(result.erro ?? 'Erro ao finalizar');
      }
    }
  }

  /// Processa o resultado da finalização e mostra dialogs apropriados
  Future<void> _processarResultadoFinalizacao(FinalizacaoResult result) async {
    if (!mounted) return;

    // Se a rua foi finalizada, mostra parabéns
    if (result.ruaFinalizada) {
      await _mostrarDialogRuaFinalizada();
      return;
    }

    // Se tem próxima OS, oferece para ir direto
    if (result.proximaOs != null) {
      await _mostrarDialogProximaOs(result.proximaOs!);
      return;
    }

    // Caso padrão: só mostra sucesso e volta
    _mostrarSucesso('Tarefa finalizada!');
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  /// Mostra dialog de parabéns quando a rua foi finalizada
  Future<void> _mostrarDialogRuaFinalizada() async {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de celebração
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '🎉 Parabéns!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Rua Finalizada!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Todas as OSs desta rua foram concluídas. Você está liberado para trabalhar em outra rua.',
                      style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Volta para a lista de ruas
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ESCOLHER NOVA RUA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vai direto para a próxima OS (sem diálogo)
  Future<void> _mostrarDialogProximaOs(ProximaOs proximaOs) async {
    if (!mounted) return;

    // Primeiro inicia a próxima OS via API
    final result = await ref
        .read(osDetalheNotifierProvider(widget.fase, proximaOs.numos).notifier)
        .iniciarOs();

    if (!result.sucesso) {
      // Mostra erro e volta para a lista
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.erro ?? 'Erro ao iniciar próxima OS'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(true);
      }
      return;
    }

    // Navega direto para a próxima OS
    Navigator.of(context).pop(true);
    // Aguarda um pouco para garantir que a navegação anterior complete
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OsEnderecoScreen(
            fase: widget.fase,
            numos: proximaOs.numos,
            faseNome: widget.faseNome,
          ),
        ),
      );
    }
  }

  /// Mostra dialog informando que deve registrar divergência antes de finalizar
  void _mostrarDialogDivergenciaObrigatoria() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[700],
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Divergência Obrigatória',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'A quantidade conferida é diferente da solicitada.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Você DEVE registrar uma divergência antes de finalizar esta OS.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use o botão "Sinalizar Problema" para registrar a divergência.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ENTENDI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogBloquear(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final motivoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de arraste
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ícone de alerta ou loading
                    if (isLoading) ...[
                      const SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bloqueando...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aguarde, processando sua solicitação',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.block_rounded,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Título
                      Text(
                        'Bloquear Tarefa?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Descrição
                      Text(
                        'A tarefa será bloqueada e voltará para a fila.\nEsta ação pode ser desfeita pelo supervisor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo de motivo
                      TextField(
                        controller: motivoController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Motivo do bloqueio *',
                          hintText: 'Descreva o motivo do bloqueio...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Botões
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Cancelar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final motivo = motivoController.text.trim();
                                if (motivo.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Informe o motivo do bloqueio',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isLoading = true);

                                final (sucesso, erro) = await ref
                                    .read(
                                      osDetalheNotifierProvider(
                                        widget.fase,
                                        widget.numos,
                                      ).notifier,
                                    )
                                    .bloquear(motivo);

                                if (!mounted) return;

                                // Fecha o bottom sheet primeiro
                                Navigator.of(ctx).pop();

                                if (sucesso) {
                                  // Pop the bipar screen - must happen even if SnackBar fails
                                  if (mounted) {
                                    Navigator.of(this.context).pop(true);
                                  }
                                } else {
                                  if (mounted) {
                                    _mostrarErro(
                                      erro ?? 'Erro ao bloquear',
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Bloquear',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogDivergencia(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final observacaoController = TextEditingController();
    String? tipoSelecionado;

    // Tipos de divergência conforme API
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
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de arraste
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ícone de alerta
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 40,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Título
                    Text(
                      'Sinalizar Divergência',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Descrição
                    Text(
                      'Selecione o tipo da divergência encontrada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dropdown de tipo
                    DropdownButtonFormField<String>(
                      value: tipoSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Tipo da divergência *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade50,
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: Colors.orange.shade300,
                        ),
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                      items: tiposDivergencia.map((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo['value'] as String,
                          child: Text(tipo['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          tipoSelecionado = value;
                          // Limpa observação se mudar de "outro" para outro tipo
                          if (value != 'outro') {
                            observacaoController.clear();
                          }
                        });
                      },
                    ),

                    // Campo de observação (só aparece se for "outro")
                    if (isOutro) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: observacaoController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Descreva a divergência *',
                          hintText: 'Informe detalhes da divergência...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade50,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 48),
                            child: Icon(
                              Icons.edit_note,
                              color: Colors.orange.shade300,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Cancelar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              if (tipoSelecionado == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Selecione o tipo da divergência',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              final observacao = observacaoController.text
                                  .trim();

                              // Se for "outro", observação é obrigatória
                              if (tipoSelecionado == 'outro' &&
                                  observacao.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Descreva a divergência'),
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
                                    observacao.isNotEmpty ? observacao : null,
                                  );
                              if (sucesso && mounted) {
                                _mostrarSucesso('Divergência sinalizada!');
                              } else {
                                _mostrarErro(erro ?? 'Erro ao sinalizar');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Confirmar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
        },
      ),
    );
  }

  void _mostrarEstoques(BuildContext context, int codprod, String descricao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header compacto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Estoques - Cód: $codprod',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),

            // Lista de estoques
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final estoquesAsync = ref.watch(consultaEstoqueProvider(codprod));
                  return estoquesAsync.when(
                    data: (estoques) {
                      if (estoques.isEmpty) {
                        return const Center(
                          child: Text('Nenhum estoque encontrado'),
                        );
                      }

                      // Calcula total
                      final total = estoques.fold<double>(0, (sum, e) => sum + e.quantidade);

                      return Column(
                        children: [
                          // Total compacto
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'TOTAL: ',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${total.toStringAsFixed(0)} UN',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Lista simples
                          Expanded(
                            child: ListView.separated(
                              itemCount: estoques.length,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                              itemBuilder: (_, i) {
                                final e = estoques[i];
                                final endereco = e.endereco.isNotEmpty
                                    ? e.endereco
                                    : '${e.rua}.${e.predio}.${e.nivel}.${e.apto}';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          endereco,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green[700],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${e.quantidade.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text('Erro: $e', style: const TextStyle(fontSize: 12)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCalculadora(BuildContext context, OsDetalhe os) {
    final ctrlUn = TextEditingController();
    final ctrlCx = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.calculate, color: Colors.amber[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('CALCULADORA', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info do múltiplo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '1 CX = ${os.multiplo} UN',
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Campos de conversão
              Row(
                children: [
                  // Campo Unidades
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'UNIDADES',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: ctrlUn,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            final un = int.tryParse(value) ?? 0;
                            final cx = os.multiplo > 0
                                ? (un / os.multiplo)
                                : 0.0;
                            ctrlCx.text = cx.toStringAsFixed(2);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Ícone de conversão
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.swap_horiz,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  // Campo Caixas
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'CAIXAS',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: ctrlCx,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (value) {
                            final cx =
                                double.tryParse(value.replaceAll(',', '.')) ??
                                0;
                            final un = (cx * os.multiplo).round();
                            ctrlUn.text = un.toString();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Botões de atalho
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [1, 2, 5, 10].map((cx) {
                  return ActionChip(
                    label: Text('$cx CX'),
                    onPressed: () {
                      ctrlCx.text = cx.toString();
                      ctrlUn.text = (cx * os.multiplo).toString();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  void _mostrarSucesso(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
