import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../shared/providers/api_service_provider.dart';
import '../../../../shared/widgets/autorizar_digitacao_dialog.dart';
import 'unitizador_itens_screen.dart';
import 'carrinho_screen.dart';

/// Tela de lista de unitizadores para Fase 2
/// Operador DEVE bipar o código de barras do unitizador antes de conferir itens
class UnitizadorListScreen extends ConsumerStatefulWidget {
  final String rua;

  const UnitizadorListScreen({super.key, required this.rua});

  @override
  ConsumerState<UnitizadorListScreen> createState() =>
      _UnitizadorListScreenState();
}

class _UnitizadorListScreenState extends ConsumerState<UnitizadorListScreen> {
  List<Map<String, dynamic>> _unitizadores = [];
  bool _isLoading = true;
  String? _erro;
  int _itensNoCarrinho = 0;

  // Controller para bipagem do unitizador
  final _codigoController = TextEditingController();
  final _codigoFocusNode = FocusNode();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Esconde teclado quando foca (para scanner físico)
    _codigoFocusNode.addListener(_esconderTeclado);

    // Atualiza UI quando texto muda
    _codigoController.addListener(() {
      if (mounted) setState(() {});
    });

    _carregarUnitizadores();
    _carregarCarrinho();

    // Foca no campo de scanner após build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codigoFocusNode.requestFocus();
      // Esconde teclado após um pequeno delay
      Future.delayed(const Duration(milliseconds: 100), () {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      });
    });
  }

  void _esconderTeclado() {
    if (_codigoFocusNode.hasFocus) {
      // Usa delay para garantir que esconde após o sistema tentar abrir
      Future.delayed(const Duration(milliseconds: 50), () {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      });
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _codigoFocusNode.dispose();
    super.dispose();
  }

  Future<void> _carregarCarrinho() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/wms/fase2/meu-carrinho');

      if (!mounted) return;

      final carrinho = response['carrinho'] as List? ?? [];
      setState(() {
        _itensNoCarrinho = carrinho.length;
      });
    } catch (_) {}
  }

  Future<void> _carregarUnitizadores() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get(
        '/wms/fase2/ruas/${widget.rua}/unitizadores',
      );

      if (!mounted) return;

      final lista = response['unitizadores'] as List? ?? [];
      setState(() {
        _unitizadores = lista.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1117)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Rua ${widget.rua}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
            Text(
              'Unitizadores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Botão do carrinho
          if (_itensNoCarrinho > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Badge(
                  label: Text(
                    '$_itensNoCarrinho',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.orange,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_rounded,
                      size: 18,
                      color: Colors.orange,
                    ),
                  ),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
                  );
                  if (result == true && mounted) {
                    _carregarCarrinho();
                    _carregarUnitizadores();
                  }
                },
              ),
            ),
          // Botão refresh
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              onPressed: () {
                _carregarUnitizadores();
                _carregarCarrinho();
              },
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Carregando unitizadores...',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Erro ao carregar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _erro!.replaceAll('Exception: ', ''),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _carregarUnitizadores,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tentar novamente',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_unitizadores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  size: 56,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhum unitizador disponível',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Não há unitizadores com OSs prontas\npara conferência nesta rua.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _carregarUnitizadores,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Atualizar',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Campo de scanner para bipar unitizador
        _buildScannerInput(isDark),

        // Lista de unitizadores (apenas informativo)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _unitizadores.length + 1,
            itemBuilder: (context, index) {
              // Header com total
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bipe o código de barras do unitizador',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_unitizadores.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final unit = _unitizadores[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UnitizadorCardInfo(unitizador: unit),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Constrói o campo de scanner para bipar unitizador
  Widget _buildScannerInput(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Escanear Unitizador',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                    Text(
                      'Bipe o código de barras para conferir',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Campo de texto com KeyboardListener para scanner físico
              Expanded(
                child: KeyboardListener(
                  focusNode: _codigoFocusNode,
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent) {
                      final key = event.logicalKey;
                      // Enter - confirmar
                      if (key == LogicalKeyboardKey.enter) {
                        _biparUnitizador();
                        return;
                      }
                      // Backspace
                      if (key == LogicalKeyboardKey.backspace) {
                        if (_codigoController.text.isNotEmpty) {
                          _codigoController.text = _codigoController.text
                              .substring(0, _codigoController.text.length - 1);
                        }
                        return;
                      }
                      // Caracteres imprimíveis
                      final char = event.character;
                      if (char != null &&
                          char.isNotEmpty &&
                          char != '\n' &&
                          char != '\r') {
                        _codigoController.text += char;
                      }
                    }
                  },
                  child: GestureDetector(
                    onTap: () {
                      _codigoFocusNode.requestFocus();
                      _esconderTeclado();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_shipping_rounded,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _codigoController.text.isEmpty
                                  ? 'Aguardando leitura do unitizador...'
                                  : _codigoController.text,
                              style: TextStyle(
                                fontSize: 16,
                                color: _codigoController.text.isEmpty
                                    ? (isDark
                                          ? Colors.white38
                                          : Colors.grey.shade400)
                                    : (isDark
                                          ? Colors.white
                                          : Colors.grey.shade900),
                              ),
                            ),
                          ),
                          if (_isProcessing)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botão câmera
              GestureDetector(
                onTap: _isProcessing ? null : _abrirScannerCamera,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botão digitar (requer autorização)
              GestureDetector(
                onTap: _isProcessing ? null : _solicitarAutorizacaoDigitar,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.keyboard_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bipa o unitizador e navega para conferência
  Future<void> _biparUnitizador() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty || _isProcessing) return;

    // Remove o foco antes de processar para evitar conflito no Flutter Web
    _codigoFocusNode.unfocus();

    setState(() => _isProcessing = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/wms/fase2/unitizador/bipar', {
        'codigo_barras': codigo,
      });

      _codigoController.clear();

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Extrai os itens da resposta para passar à próxima tela
      final itens = (response['itens'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      // Navega para a tela de conferência de itens
      final resultado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => UnitizadorItensScreen(
            codigoBarras: codigo,
            rua: widget.rua,
            itensIniciais: itens,
          ),
        ),
      );

      if (resultado == true) {
        _carregarUnitizadores();
        _carregarCarrinho();

        // Mostra sucesso rápido
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Produto adicionado ao carrinho!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }

      // Refoca no campo de scanner com delay para evitar conflito DOM
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _codigoFocusNode.requestFocus();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);

      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      _codigoController.clear();
      // Refoca com delay para evitar conflito DOM
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _codigoFocusNode.requestFocus();
      });
    }
  }

  /// Abre scanner de câmera
  void _abrirScannerCamera() {
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
                      'Escanear Unitizador',
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
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    final code = barcodes.first.rawValue!;
                    Navigator.pop(context);
                    _codigoController.text = code;
                    _biparUnitizador();
                  }
                },
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
      _mostrarDialogDigitar();
    }
  }

  /// Mostra dialog para digitar código manualmente (após autorização)
  void _mostrarDialogDigitar() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.keyboard_rounded,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Digitar Código',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Código do unitizador...',
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(ctx);
              _codigoController.text = value.trim();
              _biparUnitizador();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _codigoController.text = controller.text.trim();
                _biparUnitizador();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

/// Card informativo do unitizador (sem interação de tap)
/// Operador deve bipar o código de barras ao invés de clicar
class _UnitizadorCardInfo extends StatelessWidget {
  final Map<String, dynamic> unitizador;

  const _UnitizadorCardInfo({required this.unitizador});

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'EM_CONFERENCIA':
        return Colors.orange;
      case 'CONFERIDO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toUpperCase()) {
      case 'EM_CONFERENCIA':
        return 'Em conferência';
      case 'CONFERIDO':
        return 'Conferido';
      default:
        return 'Aguardando';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtdItens = unitizador['qtd_itens'] ?? 0;
    final qtdConferidos = unitizador['qtd_conferidos'] ?? 0;
    final codigo =
        unitizador['codunitizador'] ?? unitizador['codigo_barras'] ?? '---';
    final status = unitizador['status']?.toString();
    final statusColor = _getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone do unitizador
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                color: statusColor,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // Informações do unitizador
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unitizador $codigo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$qtdConferidos/$qtdItens conferidos',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(status),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
