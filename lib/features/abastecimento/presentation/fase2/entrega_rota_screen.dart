import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../shared/providers/api_service_provider.dart';
import '../../../../shared/widgets/autorizar_digitacao_dialog.dart';

/// Tela de entrega - mostra a rota e permite confirmar entregas
class EntregaRotaScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> rota;

  const EntregaRotaScreen({super.key, required this.rota});

  @override
  ConsumerState<EntregaRotaScreen> createState() => _EntregaRotaScreenState();
}

class _EntregaRotaScreenState extends ConsumerState<EntregaRotaScreen> {
  late List<Map<String, dynamic>> _rota;
  int _indiceAtual = 0;
  bool _entregando = false;
  
  // Etapa: 0 = bipar endereço, 1 = bipar produto
  int _etapa = 0;
  String _codigoEndereco = '';
  
  // Controllers para scanner
  final _codigoController = TextEditingController();
  final _codigoFocusNode = FocusNode();
  bool _tecladoLiberado = false;

  @override
  void initState() {
    super.initState();
    _rota = List.from(widget.rota);
    
    // Esconde teclado quando foca (para scanner físico)
    _codigoFocusNode.addListener(_onFocusChange);
    
    // Foca no campo após build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codigoFocusNode.requestFocus();
    });
  }
  
  void _onFocusChange() {
    if (_codigoFocusNode.hasFocus && !_tecladoLiberado) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _codigoFocusNode.removeListener(_onFocusChange);
    _codigoFocusNode.dispose();
    super.dispose();
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
    } else if (enderecoDestinoField is String &&
        enderecoDestinoField.isNotEmpty) {
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
                _buildItemAtualCard(
                  isDark,
                  item,
                  enderecoStr,
                  descricao,
                  qt,
                  ordem,
                ),

                const SizedBox(height: 20),

                // Lista de próximos itens
                if (_rota.length > 1) _buildProximosItens(isDark),
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

  Widget _buildItemAtualCard(
    bool isDark,
    Map<String, dynamic> item,
    String endereco,
    String descricao,
    double qt,
    dynamic ordem,
  ) {
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
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              descricao,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : Colors.grey.shade800,
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
                          _buildInfoChip(
                            isDark,
                            Icons.tag,
                            'Cód: ${item['codprod']}',
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            isDark,
                            Icons.scale,
                            '${qt.toStringAsFixed(0)} UN',
                          ),
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
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
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
            itemEndereco =
                enderecoDestinoField['endereco']?.toString() ?? '---';
          } else if (enderecoDestinoField is String &&
              enderecoDestinoField.isNotEmpty) {
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

  Widget _buildBottomBar(
    bool isDark,
    String endereco,
    Map<String, dynamic> item,
  ) {
    // Etapa 0: bipar produto (pegar do carrinho)
    // Etapa 1: bipar endereço (confirmar entrega)
    final instrucao = _etapa == 0 
        ? 'Bipe o produto: ${item['descricao']}'
        : 'Bipe o endereço: $endereco';
    final hintText = _etapa == 0 
        ? 'Aguardando leitura do produto...'
        : 'Aguardando leitura do endereço...';
        
    return Container(
      padding: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de etapa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _etapa == 0 
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _etapa == 0 ? Icons.inventory_2 : Icons.location_on,
                    size: 16,
                    color: _etapa == 0 ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    instrucao,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _etapa == 0 ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Campo de scanner
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _codigoFocusNode.hasFocus
                      ? (_etapa == 0 ? Colors.orange : Colors.green)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codigoController,
                      focusNode: _codigoFocusNode,
                      enabled: !_entregando,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.qr_code_scanner,
                          color: _etapa == 0 ? Colors.blue : Colors.orange,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                      keyboardType: _tecladoLiberado 
                          ? TextInputType.text 
                          : TextInputType.none,
                      onSubmitted: (_) => _processarCodigo(item, endereco),
                    ),
                  ),
                  // Botão câmera
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      color: _etapa == 0 ? Colors.blue : Colors.orange,
                    ),
                    onPressed: _entregando ? null : () => _abrirCameraEntrega(item, endereco),
                  ),
                  // Loading
                  if (_entregando)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Botões auxiliares
            Row(
              children: [
                // Botão digitar
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _entregando ? null : () => _solicitarAutorizacaoDigitar(item, endereco),
                    icon: const Icon(Icons.keyboard, size: 18),
                    label: const Text('DIGITAR'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botão confirmar
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _entregando || _codigoController.text.isEmpty
                        ? null
                        : () => _processarCodigo(item, endereco),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('CONFIRMAR'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
  
  // Guarda código do produto bipado na etapa 0
  String _codigoProduto = '';
  
  /// Processa o código bipado
  Future<void> _processarCodigo(Map<String, dynamic> item, String enderecoEsperado) async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) return;
    
    if (_etapa == 0) {
      // Etapa 0: Validando produto - guarda para enviar depois
      // A validação real será feita pela API
      setState(() {
        _codigoProduto = codigo;
        _etapa = 1;
        _codigoController.clear();
        _tecladoLiberado = false;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _codigoFocusNode.requestFocus();
      });
      
    } else {
      // Etapa 1: Validando endereço - aceita se contém o endereço esperado
      final enderecoFormatado = enderecoEsperado.replaceAll('.', '').toUpperCase();
      final codigoFormatado = codigo.replaceAll('.', '').toUpperCase();
      
      if (!codigoFormatado.contains(enderecoFormatado) && !enderecoFormatado.contains(codigoFormatado)) {
        _mostrarErro('Endereço incorreto! Esperado: $enderecoEsperado');
        _codigoController.clear();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _codigoFocusNode.requestFocus();
        });
        return;
      }
      
      // Endereço OK, confirma entrega na API
      await _confirmarEntregaApi(item, codigo, _codigoProduto);
    }
  }
  
  /// Confirma entrega na API
  Future<void> _confirmarEntregaApi(
    Map<String, dynamic> item,
    String codigoEndereco,
    String codigoProduto,
  ) async {
    setState(() => _entregando = true);
    
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase2/os/${item['numos']}/confirmar-entrega', {
        'codigo_barras_endereco': codigoEndereco,
        'codigo_barras_produto': codigoProduto,
      });
      
      if (!mounted) return;
      
      // Sucesso! Remove item e vai para próximo
      setState(() {
        _rota.removeAt(_indiceAtual);
        if (_indiceAtual >= _rota.length && _rota.isNotEmpty) {
          _indiceAtual = _rota.length - 1;
        }
        _etapa = 0;
        _codigoEndereco = '';
        _codigoProduto = '';
        _codigoController.clear();
        _entregando = false;
        _tecladoLiberado = false;
      });
      
      // Se ainda tem itens, foca para próximo com delay
      if (_rota.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _codigoFocusNode.requestFocus();
        });
      }
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _entregando = false);
      _mostrarErro(e.toString().replaceAll('Exception: ', ''));
      _codigoController.clear();
      // Refoca com delay para evitar conflito DOM no Flutter Web
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _codigoFocusNode.requestFocus();
      });
    }
  }
  
  /// Abre câmera para entrega
  void _abrirCameraEntrega(Map<String, dynamic> item, String endereco) {
    // Etapa 0: produto, Etapa 1: endereço
    final titulo = _etapa == 0 ? 'Escanear Produto' : 'Escanear Endereço';
    
    _abrirCamera(
      titulo: titulo,
      instrucao: _etapa == 0 ? 'Escaneie o código do produto' : 'Escaneie o endereço $endereco',
      onScanned: (codigo) {
        Navigator.pop(context);
        _codigoController.text = codigo;
        _processarCodigo(item, endereco);
      },
    );
  }
  
  /// Solicita autorização para digitar manualmente
  Future<void> _solicitarAutorizacaoDigitar(Map<String, dynamic> item, String endereco) async {
    final apiService = ref.read(apiServiceProvider);
    
    final autorizado = await AutorizarDigitacaoDialog.mostrar(
      context: context,
      apiService: apiService,
    );
    
    if (autorizado == true && mounted) {
      setState(() => _tecladoLiberado = true);
      _codigoFocusNode.requestFocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      });
    }
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

  /// Abre câmera para escanear código de barras
  void _abrirCamera({
    required String titulo,
    required String instrucao,
    required void Function(String codigo) onScanned,
  }) {
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
                  Text(
                    titulo,
                    style: const TextStyle(
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
                    if (barcodes.isNotEmpty &&
                        barcodes.first.rawValue != null) {
                      final codigo = barcodes.first.rawValue!;
                      Navigator.pop(ctx);
                      onScanned(codigo);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                instrucao,
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

  Future<void> _confirmarEntrega(
    Map<String, dynamic> item,
    String enderecoEsperado,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extrair codauxiliar (código de barras esperado do produto)
    final codauxiliar = item['codauxiliar']?.toString() ?? '';
    final descricao = item['descricao'] ?? 'Produto ${item['codprod']}';

    // Resultado da confirmação - inclui dados da resposta da API
    Map<String, dynamic>? resultadoApi;

    // Abre modal para confirmar endereço e produto
    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Etapa: 0 = bipar endereço, 1 = bipar produto, 2 = confirmando
        int etapa = 0;
        String codigoEndereco = '';
        String codigoProduto = '';
        bool isLoading = false;
        String? erro;
        bool tecladoLiberado = false;

        final enderecoController = TextEditingController();
        final produtoController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> confirmarNaApi() async {
              setModalState(() {
                etapa = 2;
                isLoading = true;
                erro = null;
              });

              try {
                final apiService = ref.read(apiServiceProvider);
                final response = await apiService
                    .post('/wms/fase2/os/${item['numos']}/confirmar-entrega', {
                      'codigo_barras_endereco': codigoEndereco,
                      'codigo_barras_produto': codigoProduto,
                    });

                // Salva resultado para usar depois de fechar o modal
                resultadoApi = response;

                if (ctx.mounted) {
                  Navigator.pop(ctx, true);
                }
              } catch (e) {
                setModalState(() {
                  erro = e.toString().replaceAll('Exception: ', '');
                  isLoading = false;
                  // Volta para a etapa do produto para tentar novamente
                  etapa = 1;
                });
              }
            }

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
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Indicador de etapas
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              _buildEtapaIndicador(
                                isDark: isDark,
                                numero: 1,
                                titulo: 'Endereço',
                                ativo: etapa >= 0,
                                concluido: etapa > 0,
                              ),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: etapa > 0
                                      ? Colors.green
                                      : (isDark
                                            ? Colors.white24
                                            : Colors.grey.shade300),
                                ),
                              ),
                              _buildEtapaIndicador(
                                isDark: isDark,
                                numero: 2,
                                titulo: 'Produto',
                                ativo: etapa >= 1,
                                concluido: etapa > 1,
                              ),
                            ],
                          ),
                        ),

                        // ETAPA 0: Bipar endereço
                        if (etapa == 0) ...[
                          _buildEtapaEndereco(
                            isDark: isDark,
                            enderecoEsperado: enderecoEsperado,
                            controller: enderecoController,
                            isLoading: isLoading,
                            erro: erro,
                            tecladoLiberado: tecladoLiberado,
                            onConfirmar: (codigo) {
                              setModalState(() {
                                codigoEndereco = codigo;
                                etapa = 1;
                                erro = null;
                                tecladoLiberado =
                                    false; // Reset ao mudar de etapa
                              });
                            },
                            onCancelar: () => Navigator.pop(ctx, false),
                            onAbrirCamera: () => _abrirCamera(
                              titulo: 'Escanear Endereço',
                              instrucao:
                                  'Aponte a câmera para o código do endereço',
                              onScanned: (codigo) {
                                enderecoController.text = codigo;
                                setModalState(() {
                                  codigoEndereco = codigo;
                                  etapa = 1;
                                  erro = null;
                                  tecladoLiberado = false;
                                });
                              },
                            ),
                            onDigitar: () async {
                              final apiService = ref.read(apiServiceProvider);
                              final autorizado =
                                  await AutorizarDigitacaoDialog.mostrar(
                                    context: ctx,
                                    apiService: apiService,
                                  );
                              if (autorizado) {
                                setModalState(() {
                                  tecladoLiberado = true;
                                });
                              }
                            },
                            setModalState: setModalState,
                          ),
                        ],

                        // ETAPA 1: Bipar produto
                        if (etapa == 1) ...[
                          _buildEtapaProduto(
                            isDark: isDark,
                            descricao: descricao,
                            codauxiliar: codauxiliar,
                            controller: produtoController,
                            isLoading: isLoading,
                            erro: erro,
                            tecladoLiberado: tecladoLiberado,
                            onConfirmar: (codigo) {
                              codigoProduto = codigo;
                              confirmarNaApi();
                            },
                            onVoltar: () {
                              setModalState(() {
                                etapa = 0;
                                erro = null;
                                tecladoLiberado = false;
                              });
                            },
                            onAbrirCamera: () => _abrirCamera(
                              titulo: 'Escanear Produto',
                              instrucao:
                                  'Aponte a câmera para o código de barras do produto',
                              onScanned: (codigo) {
                                produtoController.text = codigo;
                                codigoProduto = codigo;
                                confirmarNaApi();
                              },
                            ),
                            onDigitar: () async {
                              final apiService = ref.read(apiServiceProvider);
                              final autorizado =
                                  await AutorizarDigitacaoDialog.mostrar(
                                    context: ctx,
                                    apiService: apiService,
                                  );
                              if (autorizado) {
                                setModalState(() {
                                  tecladoLiberado = true;
                                });
                              }
                            },
                            setModalState: setModalState,
                          ),
                        ],

                        // ETAPA 2: Confirmando (loading)
                        if (etapa == 2) ...[
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Confirmando entrega...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
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
      },
    );

    if (confirmado == true && mounted && resultadoApi != null) {
      // Atualiza a rota com base na resposta da API
      final rotaConcluida = resultadoApi!['rota_concluida'] == true;
      final proximaEntrega = resultadoApi!['proxima_entrega'];
      final progresso = resultadoApi!['progresso'];

      setState(() {
        // Remove o item atual
        _rota.removeAt(_indiceAtual);

        // Se tem próxima entrega, atualiza a rota
        if (proximaEntrega != null && !rotaConcluida) {
          // A resposta já vem com a próxima entrega, então a rota local já está correta
          // após remover o item atual
        }

        // Ajusta índice se necessário
        if (_indiceAtual >= _rota.length && _rota.isNotEmpty) {
          _indiceAtual = _rota.length - 1;
        }
      });

      if (!rotaConcluida && _rota.isNotEmpty) {
        final entregues = progresso?['entregues'] ?? 0;
        final total = progresso?['total'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Entrega confirmada! $entregues de $total concluídas.'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildEtapaIndicador({
    required bool isDark,
    required int numero,
    required String titulo,
    required bool ativo,
    required bool concluido,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: concluido
                ? Colors.green
                : (ativo
                      ? Colors.blue
                      : (isDark ? Colors.white24 : Colors.grey.shade300)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: concluido
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$numero',
                    style: TextStyle(
                      color: ativo
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 11,
            color: ativo
                ? (isDark ? Colors.white70 : Colors.grey.shade700)
                : (isDark ? Colors.white38 : Colors.grey.shade400),
            fontWeight: ativo ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEtapaEndereco({
    required bool isDark,
    required String enderecoEsperado,
    required TextEditingController controller,
    required bool isLoading,
    required String? erro,
    required bool tecladoLiberado,
    required void Function(String) onConfirmar,
    required VoidCallback onCancelar,
    required VoidCallback onAbrirCamera,
    required VoidCallback onDigitar,
    required void Function(void Function()) setModalState,
  }) {
    return Column(
      children: [
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
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 40,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'BIPAR ENDEREÇO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  enderecoEsperado,
                  style: const TextStyle(
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

        // Campo de endereço
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
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    keyboardType: tecladoLiberado
                        ? TextInputType.text
                        : TextInputType.none,
                    decoration: InputDecoration(
                      hintText: tecladoLiberado
                          ? 'Digite o endereço...'
                          : 'Bipe o endereço...',
                      prefixIcon: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.green,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        onConfirmar(value.trim());
                      }
                    },
                  ),
                ),
                // Botão DIGITAR
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.keyboard_rounded,
                      color: tecladoLiberado ? Colors.green : Colors.orange,
                    ),
                    tooltip: 'Digitar manualmente',
                    onPressed: isLoading || tecladoLiberado ? null : onDigitar,
                  ),
                ),
                // Botão CÂMERA
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
                    onPressed: isLoading ? null : onAbrirCamera,
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      erro,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
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
                  onPressed: isLoading ? null : onCancelar,
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
                  onPressed: isLoading
                      ? null
                      : () {
                          final endereco = controller.text.trim();
                          if (endereco.isEmpty) {
                            setModalState(() {});
                            return;
                          }
                          onConfirmar(endereco);
                        },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'PRÓXIMO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEtapaProduto({
    required bool isDark,
    required String descricao,
    required String codauxiliar,
    required TextEditingController controller,
    required bool isLoading,
    required String? erro,
    required bool tecladoLiberado,
    required void Function(String) onConfirmar,
    required VoidCallback onVoltar,
    required VoidCallback onAbrirCamera,
    required VoidCallback onDigitar,
    required void Function(void Function()) setModalState,
  }) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'BIPAR PRODUTO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                descricao,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (codauxiliar.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'EAN: $codauxiliar',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Campo de produto
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
                    controller: controller,
                    autofocus: true,
                    keyboardType: tecladoLiberado
                        ? TextInputType.number
                        : TextInputType.none,
                    decoration: InputDecoration(
                      hintText: tecladoLiberado
                          ? 'Digite o código de barras...'
                          : 'Bipe o código de barras...',
                      prefixIcon: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.blue,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        onConfirmar(value.trim());
                      }
                    },
                  ),
                ),
                // Botão DIGITAR
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.keyboard_rounded,
                      color: tecladoLiberado ? Colors.blue : Colors.orange,
                    ),
                    tooltip: 'Digitar manualmente',
                    onPressed: isLoading || tecladoLiberado ? null : onDigitar,
                  ),
                ),
                // Botão CÂMERA
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.blue,
                    ),
                    onPressed: isLoading ? null : onAbrirCamera,
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      erro,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
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
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onVoltar,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('VOLTAR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          final codigo = controller.text.trim();
                          if (codigo.isEmpty) {
                            setModalState(() {});
                            return;
                          }
                          onConfirmar(codigo);
                        },
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    isLoading ? 'CONFIRMANDO...' : 'CONFIRMAR',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        content: Text(
          'Você ainda tem ${_rota.length} ${_rota.length == 1 ? "entrega" : "entregas"} pendentes.',
        ),
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
