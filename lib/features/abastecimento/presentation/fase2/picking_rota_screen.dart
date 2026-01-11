import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../shared/providers/api_service_provider.dart';
import 'guardar_item_screen.dart';

/// Tela de rota para abastecer picking (Fase 2)
/// Mostra os itens em ordem de rota otimizada
class PickingRotaScreen extends ConsumerStatefulWidget {
  final int codunitizador;
  final String rua;

  const PickingRotaScreen({
    super.key,
    required this.codunitizador,
    required this.rua,
  });

  @override
  ConsumerState<PickingRotaScreen> createState() => _PickingRotaScreenState();
}

class _PickingRotaScreenState extends ConsumerState<PickingRotaScreen> {
  List<Map<String, dynamic>> _rota = [];
  bool _isLoading = true;
  String? _erro;
  int _itemAtual = 0;

  @override
  void initState() {
    super.initState();
    _calcularRota();
  }

  Future<void> _calcularRota() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/abastecimento/fase2/rua/${widget.rua}/calcular-rota', {});
      
      final lista = response['rota'] as List? ?? [];
      setState(() {
        _rota = lista.cast<Map<String, dynamic>>();
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
        title: const Text('Abastecer Picking'),
        centerTitle: true,
      ),
      body: _buildBody(),
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
              Text('Erro ao calcular rota', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calcularRota,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rota.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text('Todos os itens foram guardados!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('VOLTAR'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com progresso
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Icon(Icons.route, color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rota de Abastecimento',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '$_itemAtual/${_rota.length} itens guardados',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_rota.length} itens',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        
        // Barra de progresso
        LinearProgressIndicator(
          value: _rota.isEmpty ? 0 : _itemAtual / _rota.length,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),

        // Lista de itens da rota
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _rota.length,
            itemBuilder: (context, index) {
              final item = _rota[index];
              final endereco = item['endereco_destino'] as Map<String, dynamic>?;
              final isAtual = index == _itemAtual;
              final isFeito = index < _itemAtual;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isAtual ? 4 : 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isAtual ? Border.all(color: Colors.orange, width: 2) : null,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isFeito 
                            ? Colors.green 
                            : isAtual 
                                ? Colors.orange 
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: isFeito 
                            ? const Icon(Icons.check, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isAtual ? Colors.white : null,
                                ),
                              ),
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
                        Text('Qtd: ${_parseNum(item['qt']).toStringAsFixed(0)}'),
                        if (endereco != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                '${endereco['rua']}.${_pad(endereco['predio'])}.${_pad(endereco['nivel'])}.${_pad(endereco['apto'])}',
                                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
                              ),
                            ],
                          ),
                      ],
                    ),
                    trailing: isAtual
                        ? FilledButton(
                            onPressed: () => _abrirGuardarItem(item),
                            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                            child: const Text('IR'),
                          )
                        : isFeito
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                            : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _pad(dynamic value) {
    return (value ?? 0).toString().padLeft(2, '0');
  }

  double _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _abrirGuardarItem(Map<String, dynamic> item) async {
    final endereco = item['endereco_destino'] as Map<String, dynamic>?;
    
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => GuardarItemScreen(
          numos: item['numos'],
          codprod: item['codprod'],
          descricao: item['descricao'] ?? 'Produto ${item['codprod']}',
          quantidade: _parseNum(item['qt']),
          codunitizador: item['codunitizador'],
          codigoBarrasUnitizador: item['codigo_barras_unitizador'] ?? '',
          endereco: endereco,
        ),
      ),
    );
    
    if (resultado == true) {
      setState(() {
        _itemAtual++;
      });
      
      // Se todos guardados, volta
      if (_itemAtual >= _rota.length) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todos os itens foram guardados!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
      }
    }
  }
}
