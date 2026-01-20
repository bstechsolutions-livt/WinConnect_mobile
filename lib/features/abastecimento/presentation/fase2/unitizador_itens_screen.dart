import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../shared/providers/api_service_provider.dart';
import '../../../../shared/widgets/autorizar_digitacao_dialog.dart';
import 'carrinho_screen.dart';

/// Tela de conferência CEGA de itens do unitizador (Fase 2)
/// Operador bipa produtos e adiciona ao carrinho direto
class UnitizadorItensScreen extends ConsumerStatefulWidget {
  final String codigoBarras;
  final String rua;
  final List<Map<String, dynamic>>? itensIniciais;

  const UnitizadorItensScreen({
    super.key,
    required this.codigoBarras,
    required this.rua,
    this.itensIniciais,
  });

  @override
  ConsumerState<UnitizadorItensScreen> createState() =>
      _UnitizadorItensScreenState();
}

class _UnitizadorItensScreenState extends ConsumerState<UnitizadorItensScreen> {
  List<Map<String, dynamic>> _itens = [];
  bool _isLoading = true;
  String? _erro;
  int _itensNoCarrinho = 0;

  // Controller para bipagem
  final _codigoController = TextEditingController();
  final _codigoFocusNode = FocusNode();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Esconde teclado quando foca (para scanner físico)
    _codigoFocusNode.addListener(() {
      if (_codigoFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    _carregarUnitizador();
    _carregarCarrinho();

    // Foca no campo após build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codigoFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _codigoFocusNode.dispose();
    super.dispose();
  }

  Future<void> _carregarUnitizador() async {
    if (!mounted) return;

    // Se já temos itens iniciais (vindos da tela anterior), usa direto
    if (widget.itensIniciais != null) {
      setState(() {
        _itens = widget.itensIniciais!;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/wms/fase2/unitizador/bipar', {
        'codigo_barras': widget.codigoBarras,
      });

      if (!mounted) return;

      setState(() {
        _itens = (response['itens'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final errorMsg = e.toString().replaceAll('Exception: ', '');

      // Verifica se é erro de "bipe o unitizador primeiro"
      final requerBipagem =
          errorMsg.toLowerCase().contains('bipe o unitizador') ||
          errorMsg.toLowerCase().contains('requer_bipagem');

      final isSemOsPendentes =
          errorMsg.toLowerCase().contains('não possui os') ||
          errorMsg.toLowerCase().contains('sem os') ||
          errorMsg.toLowerCase().contains('pendentes');

      setState(() {
        if (isSemOsPendentes) {
          _itens = [];
          _erro = null;
        } else if (requerBipagem) {
          _erro = 'Bipe o unitizador antes de conferir os itens.';
        } else {
          _erro = errorMsg;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _carregarCarrinho() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/wms/fase2/meu-carrinho');

      if (!mounted) return;

      setState(() {
        _itensNoCarrinho = response['total_itens'] ?? 0;
      });
    } catch (_) {}
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
                      _codigoController.text = codigo;
                      _processarCodigo(codigo);
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

  /// Processa o código escaneado ou digitado
  void _processarCodigo(String codigo) {
    if (codigo.isEmpty) {
      _mostrarErro('Bipe ou escaneie um código');
      return;
    }

    // Encontra o item pelo código
    final item = _itens.firstWhere(
      (i) =>
          i['codauxiliar']?.toString() == codigo ||
          i['codprod']?.toString() == codigo ||
          i['ean']?.toString() == codigo,
      orElse: () => {},
    );

    if (item.isEmpty) {
      _mostrarErro('Produto não encontrado neste unitizador');
      _codigoController.clear();
      _codigoFocusNode.requestFocus();
      return;
    }

    // Abre bottom sheet para digitar quantidades
    _abrirQuantidadeSheet(codigo, item);
  }

  /// Abre bottom sheet para digitar a quantidade
  void _abrirQuantidadeSheet(String codigo, Map<String, dynamic> item) {
    // Trata multiplo como String ou int
    int multiplo = 1;
    final m = item['multiplo'];
    if (m != null) {
      if (m is int) {
        multiplo = m;
      } else if (m is num) {
        multiplo = m.toInt();
      } else {
        multiplo = int.tryParse(m.toString()) ?? 1;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuantidadeBottomSheet(
        descricao: item['descricao'] ?? 'Produto ${item['codprod']}',
        codprod: item['codprod']?.toString() ?? '---',
        multiplo: multiplo,
        onConfirmar: (quantidade) async {
          Navigator.pop(context);
          await _conferirProduto(codigo, item, quantidade);
        },
      ),
    );
  }

  /// Confere o produto na API
  Future<void> _conferirProduto(
    String codigo,
    Map<String, dynamic> item,
    int quantidade,
  ) async {
    setState(() => _isProcessing = true);

    try {
      final apiService = ref.read(apiServiceProvider);

      await apiService.post('/wms/fase2/os/${item['numos']}/conferir-produto', {
        'codigo_barras': codigo,
        'quantidade': quantidade.toString(),
      });

      if (!mounted) return;

      // Unitizador tem só 1 item, então volta para lista de unitizadores
      // para bipar o próximo rapidamente
      Navigator.of(context).pop(true);
    } catch (e) {
      _mostrarErro(e.toString().replaceAll('Exception: ', ''));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _mostrarSucesso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirCarrinho() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CarrinhoScreen()),
    );

    if (resultado == true) {
      _carregarUnitizador();
      _carregarCarrinho();
    }
  }

  /// Solicita autorização do supervisor para digitar manualmente
  Future<void> _solicitarAutorizacaoDigitar() async {
    final autorizado = await AutorizarDigitacaoDialog.mostrar(
      context: context,
      apiService: ref.read(apiServiceProvider),
    );

    if (autorizado && mounted) {
      _codigoFocusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  /// Abre modal para registrar divergência de um item
  void _abrirDivergenciaSheet(Map<String, dynamic> item) {
    final numos = item['numos'];
    if (numos == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DivergenciaBottomSheet(
        numos: numos,
        descricao: item['descricao'] ?? 'Produto ${item['codprod']}',
        codprod: item['codprod']?.toString() ?? '---',
        qtEsperada: _parseNum(item['qt']).toInt(),
        onRegistrada: () {
          _mostrarSucesso('Divergência registrada com sucesso!');
          _carregarUnitizador();
        },
        apiService: ref.read(apiServiceProvider),
      ),
    );
  }

  double _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unitizador ${widget.codigoBarras}'),
        centerTitle: true,
        actions: [
          // Botão carrinho
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Ver carrinho',
                onPressed: _abrirCarrinho,
              ),
              if (_itensNoCarrinho > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_itensNoCarrinho',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregarUnitizador,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_itens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_outlined, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma OS pendente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Este unitizador não possui OSs\npendentes para conferência.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    final itensPendentes = _itens
        .where((i) => i['conferido'] != true && i['bloqueado'] != true)
        .toList();

    // Se não tem itens pendentes mas tem itens no carrinho, mostra opções
    if (itensPendentes.isEmpty && _itensNoCarrinho > 0) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone de sucesso
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Unitizador conferido!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Todos os itens deste unitizador\nforam conferidos com sucesso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 16),

              // Badge do carrinho
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      '$_itensNoCarrinho ${_itensNoCarrinho == 1 ? 'item' : 'itens'} no carrinho',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'O que deseja fazer?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              // Botão principal - Ir para o carrinho
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
                    );
                    if (result == true && mounted) {
                      _carregarCarrinho();
                    }
                  },
                  icon: const Icon(Icons.route),
                  label: const Text('IR PARA O CARRINHO E CRIAR ROTA'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botão secundário - Outro unitizador
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('CONFERIR OUTRO UNITIZADOR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botão atualizar
              TextButton.icon(
                onPressed: () {
                  _carregarUnitizador();
                  _carregarCarrinho();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Atualizar'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info do Unitizador
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONFERÊNCIA CEGA',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${itensPendentes.length} itens pendentes',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_itensNoCarrinho',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scanner Input - IGUAL OS OUTROS
            _buildScannerInput(context),

            const SizedBox(height: 16),

            // Lista de itens para referência
            Text(
              'Itens para conferir:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),

            // Lista compacta
            ...itensPendentes.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final descricao =
                  item['descricao'] ?? 'Produto ${item['codprod']}';
              final codprod = item['codprod']?.toString() ?? '---';
              final numos = item['numos'];

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        descricao,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#$codprod',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Botão de divergência
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: numos != null
                          ? () => _abrirDivergenciaSheet(item)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Widget de scanner igual aos outros - SEM TECLADO
  Widget _buildScannerInput(BuildContext context) {
    return Column(
      children: [
        // Campo de input
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _codigoFocusNode.hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: _codigoFocusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codigoController,
                  focusNode: _codigoFocusNode,
                  enabled: !_isProcessing,
                  readOnly: false,
                  showCursor: true,
                  decoration: InputDecoration(
                    hintText: 'Aguardando leitura do produto...',
                    prefixIcon: Icon(
                      Icons.qr_code_scanner,
                      color: _codigoFocusNode.hasFocus
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.none, // SEM TECLADO
                  onSubmitted: (value) => _processarCodigo(value.trim()),
                  onChanged: (value) {
                    // Scanner físico envia Enter no final
                    if (value.endsWith('\n') || value.endsWith('\r')) {
                      _codigoController.text = value.trim();
                      _processarCodigo(value.trim());
                    }
                  },
                ),
              ),
              if (!_isProcessing)
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Escanear com câmera',
                  onPressed: _abrirScannerCamera,
                ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use o leitor de código de barras ou toque na câmera',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _solicitarAutorizacaoDigitar(),
                icon: const Icon(Icons.keyboard, color: Colors.orange),
                label: const Text('DIGITAR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isProcessing
                    ? null
                    : () => _processarCodigo(_codigoController.text.trim()),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'CONFIRMAR',
                        style: TextStyle(
                          fontSize: 16,
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
}

// ============================================================================
// QUANTIDADE BOTTOM SHEET - Para digitar caixas e unidades
// ============================================================================

class _QuantidadeBottomSheet extends StatefulWidget {
  final String descricao;
  final String codprod;
  final int multiplo;
  final Future<void> Function(int quantidade) onConfirmar;

  const _QuantidadeBottomSheet({
    required this.descricao,
    required this.codprod,
    required this.multiplo,
    required this.onConfirmar,
  });

  @override
  State<_QuantidadeBottomSheet> createState() => _QuantidadeBottomSheetState();
}

class _QuantidadeBottomSheetState extends State<_QuantidadeBottomSheet> {
  final _caixasController = TextEditingController(text: '0');
  final _unidadesController = TextEditingController(text: '0');
  final _caixasFocus = FocusNode();
  final _unidadesFocus = FocusNode();
  bool _isConfirmando = false;

  int get _totalUnidades {
    final caixas = int.tryParse(_caixasController.text) ?? 0;
    final unidades = int.tryParse(_unidadesController.text) ?? 0;
    return (caixas * widget.multiplo) + unidades;
  }

  @override
  void initState() {
    super.initState();
    _caixasController.addListener(() => setState(() {}));
    _unidadesController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _caixasFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _caixasController.dispose();
    _unidadesController.dispose();
    _caixasFocus.dispose();
    _unidadesFocus.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_totalUnidades == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe pelo menos 1 caixa ou 1 unidade'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isConfirmando = true);
    await widget.onConfirmar(_totalUnidades);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Produto info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Produto encontrado!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.descricao,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Código: ${widget.codprod}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '1 CX = ${widget.multiplo} UN',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Título
              Text(
                'Informe a quantidade conferida:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 16),

              // Campos caixas e unidades
              Row(
                children: [
                  // Caixas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CAIXAS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _caixasController,
                          focusNode: _caixasFocus,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.green,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.green),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _unidadesFocus.requestFocus(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Unidades
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UNIDADES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _unidadesController,
                          focusNode: _unidadesFocus,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.apps_outlined,
                              color: Colors.blue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _confirmar(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Total calculado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Total: ', style: TextStyle(fontSize: 16)),
                    Text(
                      '$_totalUnidades',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(' unidades', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botão confirmar
              FilledButton.icon(
                onPressed: _isConfirmando ? null : _confirmar,
                icon: _isConfirmando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_shopping_cart),
                label: Text(
                  _isConfirmando ? 'Adicionando...' : 'ADICIONAR AO CARRINHO',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Botão cancelar
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DIVERGÊNCIA BOTTOM SHEET - Para registrar divergências
// ============================================================================

class _DivergenciaBottomSheet extends StatefulWidget {
  final dynamic numos;
  final String descricao;
  final String codprod;
  final int qtEsperada;
  final VoidCallback onRegistrada;
  final dynamic apiService;

  const _DivergenciaBottomSheet({
    required this.numos,
    required this.descricao,
    required this.codprod,
    required this.qtEsperada,
    required this.onRegistrada,
    required this.apiService,
  });

  @override
  State<_DivergenciaBottomSheet> createState() =>
      _DivergenciaBottomSheetState();
}

class _DivergenciaBottomSheetState extends State<_DivergenciaBottomSheet> {
  String? _tipoSelecionado;
  final _qtEncontradaController = TextEditingController();
  final _observacaoController = TextEditingController();
  bool _isEnviando = false;
  String? _erro;

  static const _tipos = [
    {
      'value': 'quantidade_menor',
      'label': 'Quantidade Menor',
      'icon': Icons.remove_circle_outline,
    },
    {
      'value': 'quantidade_maior',
      'label': 'Quantidade Maior',
      'icon': Icons.add_circle_outline,
    },
    {
      'value': 'produto_errado',
      'label': 'Produto Errado',
      'icon': Icons.swap_horiz,
    },
    {
      'value': 'nao_encontrado',
      'label': 'Não Encontrado',
      'icon': Icons.search_off,
    },
    {'value': 'outro', 'label': 'Outro', 'icon': Icons.more_horiz},
  ];

  Future<void> _registrarDivergencia() async {
    if (_tipoSelecionado == null) {
      setState(() => _erro = 'Selecione o tipo de divergência');
      return;
    }

    setState(() {
      _isEnviando = true;
      _erro = null;
    });

    try {
      final body = <String, dynamic>{'tipo': _tipoSelecionado};

      final qtEncontrada = int.tryParse(_qtEncontradaController.text);
      if (qtEncontrada != null) {
        body['qt_encontrada'] = qtEncontrada;
      }

      final observacao = _observacaoController.text.trim();
      if (observacao.isNotEmpty) {
        body['observacao'] = observacao;
      }

      await widget.apiService.post(
        '/wms/fase2/os/${widget.numos}/divergencia',
        body,
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onRegistrada();
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
        _isEnviando = false;
      });
    }
  }

  @override
  void dispose() {
    _qtEncontradaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registrar Divergência',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'OS #${widget.numos}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Info do produto
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.descricao,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Cód: ${widget.codprod} • Esperado: ${widget.qtEsperada} UN',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tipo de divergência
              Text(
                'Tipo de divergência *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tipos.map((tipo) {
                  final isSelected = _tipoSelecionado == tipo['value'];
                  return ChoiceChip(
                    avatar: Icon(
                      tipo['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.orange.shade700,
                    ),
                    label: Text(tipo['label'] as String),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _tipoSelecionado = selected
                            ? tipo['value'] as String
                            : null;
                        _erro = null;
                      });
                    },
                    selectedColor: Colors.orange,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Quantidade encontrada (opcional)
              Text(
                'Quantidade encontrada (opcional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _qtEncontradaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Ex: 8',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Observação (opcional)
              Text(
                'Observação (opcional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _observacaoController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Descreva o problema encontrado...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              // Erro
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _erro!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Aviso
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A OS não será bloqueada. Você pode continuar conferindo.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isEnviando
                          ? null
                          : () => Navigator.pop(context),
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
                    child: FilledButton.icon(
                      onPressed: _isEnviando ? null : _registrarDivergencia,
                      icon: _isEnviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isEnviando ? 'REGISTRANDO...' : 'REGISTRAR',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
