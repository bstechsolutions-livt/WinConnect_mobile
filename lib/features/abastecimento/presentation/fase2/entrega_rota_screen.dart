import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../shared/providers/api_service_provider.dart';

/// Tela de entrega - mostra a rota e permite confirmar entregas
class EntregaRotaScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> rota;

  const EntregaRotaScreen({
    super.key,
    required this.rota,
  });

  @override
  ConsumerState<EntregaRotaScreen> createState() => _EntregaRotaScreenState();
}

class _EntregaRotaScreenState extends ConsumerState<EntregaRotaScreen> {
  late List<Map<String, dynamic>> _rota;
  int _indiceAtual = 0;
  // ignore: prefer_final_fields
  bool _entregando = false;

  @override
  void initState() {
    super.initState();
    _rota = List.from(widget.rota);
  }

  Map<String, dynamic>? get _itemAtual => 
      _indiceAtual < _rota.length ? _rota[_indiceAtual] : null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF0D1117) 
          : const Color(0xFFF5F7FA),
      appBar: _buildAppBar(isDark),
      body: _rota.isEmpty ? _buildVazio(isDark) : _buildBody(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
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
        onPressed: () => _confirmarSaida(),
      ),
      title: Column(
        children: [
          Text(
            'Entrega',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          Text(
            'Rota de Abastecimento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildVazio(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Todas as entregas concluídas!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Parabéns! Você finalizou todas\nas entregas da rota.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'FINALIZAR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final item = _itemAtual;
    if (item == null) return _buildVazio(isDark);
    
    // Tenta buscar endereço de várias formas possíveis
    String enderecoStr = '---';
    final enderecoField = item['endereco'];
    final enderecoDestinoField = item['endereco_destino'];
    
    if (enderecoField is Map<String, dynamic>) {
      enderecoStr = enderecoField['endereco']?.toString() ?? '---';
    } else if (enderecoField is String && enderecoField.isNotEmpty) {
      enderecoStr = enderecoField;
    } else if (enderecoDestinoField is Map<String, dynamic>) {
      enderecoStr = enderecoDestinoField['endereco']?.toString() ?? '---';
    } else if (enderecoDestinoField is String && enderecoDestinoField.isNotEmpty) {
      enderecoStr = enderecoDestinoField;
    }
    
    final descricao = item['descricao'] ?? 'Produto ${item['codprod']}';
    final qt = _parseNum(item['qt']);
    final ordem = item['ordem'] ?? (_indiceAtual + 1);
    
    return Column(
      children: [
        // Progress bar
        _buildProgressBar(isDark),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Card do item atual
                _buildItemAtualCard(isDark, item, enderecoStr, descricao, qt, ordem),
                
                const SizedBox(height: 20),
                
                // Lista de próximos itens
                if (_rota.length > 1)
                  _buildProximosItens(isDark),
              ],
            ),
          ),
        ),
        
        // Botão de confirmar entrega
        _buildBottomBar(isDark, enderecoStr, item),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progresso = _rota.isEmpty ? 1.0 : (_indiceAtual / widget.rota.length);
    final entregues = widget.rota.length - _rota.length;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso da Rota',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              Text(
                '$entregues de ${widget.rota.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 10,
              backgroundColor: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemAtualCard(bool isDark, Map<String, dynamic> item, String endereco, String descricao, double qt, dynamic ordem) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$ordem',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRÓXIMA ENTREGA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Item ${_indiceAtual + 1} de ${_rota.length}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${item['numos']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Endereço destaque
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.green,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ENTREGAR EM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        endereco,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Info do produto
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              descricao,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(isDark, Icons.tag, 'Cód: ${item['codprod']}'),
                          const SizedBox(width: 12),
                          _buildInfoChip(isDark, Icons.scale, '${qt.toStringAsFixed(0)} UN'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(bool isDark, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProximosItens(bool isDark) {
    final proximos = _rota.skip(_indiceAtual + 1).take(3).toList();
    
    if (proximos.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos na fila',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        ...proximos.map((item) {
          // Tenta buscar endereço de várias formas possíveis
          String itemEndereco = '---';
          final enderecoField = item['endereco'];
          final enderecoDestinoField = item['endereco_destino'];
          
          if (enderecoField is Map<String, dynamic>) {
            itemEndereco = enderecoField['endereco']?.toString() ?? '---';
          } else if (enderecoField is String && enderecoField.isNotEmpty) {
            itemEndereco = enderecoField;
          } else if (enderecoDestinoField is Map<String, dynamic>) {
            itemEndereco = enderecoDestinoField['endereco']?.toString() ?? '---';
          } else if (enderecoDestinoField is String && enderecoDestinoField.isNotEmpty) {
            itemEndereco = enderecoDestinoField;
          }
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${item['ordem']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['descricao'] ?? 'Produto ${item['codprod']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  itemEndereco,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark, String endereco, Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _entregando ? null : () => _confirmarEntrega(item, endereco),
            icon: _entregando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded, size: 24),
            label: Text(
              _entregando ? 'CONFIRMANDO...' : 'CONFIRMAR ENTREGA',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Abre câmera para escanear código de barras do endereço
  /// Se onScanned for fornecido, executa automaticamente após escanear
  void _abrirCameraEndereco(
    TextEditingController controller, 
    void Function(void Function()) setModalState,
    {Future<void> Function(String codigo)? onScanned}
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Text(
                    'Escanear Endereço',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
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
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      final codigo = barcodes.first.rawValue!;
                      Navigator.pop(ctx);
                      controller.text = codigo;
                      
                      // Se tiver callback, executa automaticamente
                      if (onScanned != null) {
                        onScanned(codigo);
                      } else {
                        setModalState(() {});
                      }
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

  Future<void> _confirmarEntrega(Map<String, dynamic> item, String enderecoEsperado) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enderecoController = TextEditingController();
    final focusNode = FocusNode();
    
    // Abre modal para confirmar endereço
    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isLoading = false;
        String? erro;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  size: 40,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'CONFIRMAR ENDEREÇO',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  enderecoEsperado,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Campo de endereço - COM TECLADO
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: enderecoController,
                                    focusNode: focusNode,
                                    autofocus: true,
                                    readOnly: false,
                                    showCursor: true,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      hintText: 'Digite ou bipe o endereço...',
                                      prefixIcon: Icon(
                                        Icons.qr_code_scanner,
                                        color: Colors.green,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      // Scanner físico envia Enter no final
                                      if (value.endsWith('\n') || value.endsWith('\r')) {
                                        enderecoController.text = value.trim();
                                        setModalState(() {});
                                      }
                                    },
                                  ),
                                ),
                                // Botão de câmera
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.green,
                                    ),
                                    onPressed: isLoading ? null : () => _abrirCameraEndereco(
                                      enderecoController, 
                                      setModalState,
                                      onScanned: (codigo) async {
                                        // Confirma automaticamente ao escanear
                                        setModalState(() {
                                          isLoading = true;
                                          erro = null;
                                        });
                                        
                                        try {
                                          final apiService = ref.read(apiServiceProvider);
                                          await apiService.post(
                                            '/wms/fase2/os/${item['numos']}/confirmar-entrega',
                                            {'codigo_barras_endereco': codigo},
                                          );
                                          
                                          if (ctx.mounted) {
                                            Navigator.pop(ctx, true);
                                          }
                                        } catch (e) {
                                          setModalState(() {
                                            erro = e.toString().replaceAll('Exception: ', '');
                                            isLoading = false;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Erro
                        if (erro != null)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      erro!,
                                      style: TextStyle(color: Colors.red, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Botões
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isLoading ? null : () => Navigator.pop(ctx, false),
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
                                          final endereco = enderecoController.text.trim();
                                          
                                          if (endereco.isEmpty) {
                                            setModalState(() => erro = 'Digite ou bipe o endereço');
                                            return;
                                          }
                                          
                                          setModalState(() {
                                            isLoading = true;
                                            erro = null;
                                          });
                                          
                                          try {
                                            final apiService = ref.read(apiServiceProvider);
                                            await apiService.post(
                                              '/wms/fase2/os/${item['numos']}/confirmar-entrega',
                                              {'codigo_barras_endereco': endereco},
                                            );
                                            
                                            if (ctx.mounted) {
                                              Navigator.pop(ctx, true);
                                            }
                                          } catch (e) {
                                            setModalState(() {
                                              erro = e.toString().replaceAll('Exception: ', '');
                                              isLoading = false;
                                            });
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green,
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
                                          'CONFIRMAR',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    
    if (confirmado == true && mounted) {
      // Remove o item da lista e avança
      setState(() {
        _rota.removeAt(_indiceAtual);
        if (_indiceAtual >= _rota.length && _rota.isNotEmpty) {
          _indiceAtual = _rota.length - 1;
        }
      });
      
      if (_rota.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Entrega confirmada! ${_rota.length} restantes.'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _confirmarSaida() async {
    if (_rota.isEmpty) {
      Navigator.pop(context, true);
      return;
    }
    
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da rota?'),
        content: Text('Você ainda tem ${_rota.length} ${_rota.length == 1 ? "entrega" : "entregas"} pendentes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SAIR'),
          ),
        ],
      ),
    );
    
    if (sair == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  double _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
