import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../shared/providers/api_service_provider.dart';
import 'conferencia_screen.dart';
import 'picking_rota_screen.dart';

/// Tela de itens de um unitizador para conferência (Fase 2)
class UnitizadorItensScreen extends ConsumerStatefulWidget {
  final int codunitizador;
  final String rua;

  const UnitizadorItensScreen({
    super.key,
    required this.codunitizador,
    required this.rua,
  });

  @override
  ConsumerState<UnitizadorItensScreen> createState() => _UnitizadorItensScreenState();
}

class _UnitizadorItensScreenState extends ConsumerState<UnitizadorItensScreen> {
  List<Map<String, dynamic>> _itens = [];
  bool _isLoading = true;
  String? _erro;
  bool _todasConferidas = false;

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  Future<void> _carregarItens() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/abastecimento/fase2/unitizador/${widget.codunitizador}/itens');
      
      final lista = response['itens'] as List? ?? [];
      setState(() {
        _itens = lista.cast<Map<String, dynamic>>();
        _todasConferidas = response['todas_conferidas'] == true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unitizador ${widget.codunitizador}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarItens,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _todasConferidas ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Erro ao carregar itens', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregarItens,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_itens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 24),
            Text('Nenhum item para conferir', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com resumo
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Icon(Icons.local_shipping, color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conferência Cega',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${_itens.where((i) => i['conferido'] == true).length}/${_itens.length} itens conferidos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (_todasConferidas)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('PRONTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        
        // Lista de itens
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _itens.length,
            itemBuilder: (context, index) {
              final item = _itens[index];
              final conferido = item['conferido'] == true;
              final bloqueado = item['status'] == 'BLOQUEADA';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: bloqueado 
                          ? Colors.red 
                          : conferido 
                              ? Colors.green 
                              : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bloqueado 
                            ? Colors.red 
                            : conferido 
                                ? Colors.green 
                                : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        bloqueado 
                            ? Icons.lock 
                            : conferido 
                                ? Icons.check 
                                : Icons.inventory_2,
                        color: bloqueado || conferido 
                            ? Colors.white 
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      item['descricao'] ?? 'Produto ${item['codprod']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cód: ${item['codprod']}'),
                        Text(
                          'Qtd: ${_parseNum(item['qt']).toStringAsFixed(0)} ${item['unidade'] ?? 'UN'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (bloqueado)
                          const Text('BLOQUEADA', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: bloqueado 
                        ? const Icon(Icons.lock, color: Colors.red, size: 32)
                        : conferido 
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                            : const Icon(Icons.chevron_right),
                    onTap: bloqueado || conferido ? null : () => _abrirConferencia(item),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _abrirRotaAbastecer,
            icon: const Icon(Icons.route),
            label: const Text('ABASTECER PICKING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirConferencia(Map<String, dynamic> item) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ConferenciaScreen(
          numos: item['numos'],
          codprod: item['codprod'],
          descricao: item['descricao'] ?? 'Produto ${item['codprod']}',
          codauxiliar: (item['codauxiliar'] ?? '').toString(),
          quantidade: _parseNum(item['qt']),
          unidade: item['unidade'] ?? 'UN',
        ),
      ),
    );
    
    if (resultado == true) {
      _carregarItens();
    }
  }

  double _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _abrirRotaAbastecer() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PickingRotaScreen(
          codunitizador: widget.codunitizador,
          rua: widget.rua,
        ),
      ),
    );
    
    if (resultado == true) {
      // Recarrega itens ou volta para lista de unitizadores
      Navigator.of(context).pop(true);
    }
  }
}
