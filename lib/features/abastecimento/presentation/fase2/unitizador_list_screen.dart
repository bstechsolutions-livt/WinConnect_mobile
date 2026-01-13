import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../shared/providers/api_service_provider.dart';
import 'unitizador_itens_screen.dart';

/// Tela de lista de unitizadores para Fase 2
class UnitizadorListScreen extends ConsumerStatefulWidget {
  final String rua;

  const UnitizadorListScreen({
    super.key,
    required this.rua,
  });

  @override
  ConsumerState<UnitizadorListScreen> createState() => _UnitizadorListScreenState();
}

class _UnitizadorListScreenState extends ConsumerState<UnitizadorListScreen> {
  List<Map<String, dynamic>> _unitizadores = [];
  bool _isLoading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarUnitizadores();
  }

  Future<void> _carregarUnitizadores() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/wms/fase2/ruas/${widget.rua}/unitizadores');
      
      final lista = response['unitizadores'] as List? ?? [];
      setState(() {
        _unitizadores = lista.cast<Map<String, dynamic>>();
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
        title: Text('Rua ${widget.rua} - Unitizadores'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarUnitizadores,
          ),
        ],
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
              Text('Erro ao carregar unitizadores', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_erro!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregarUnitizadores,
                child: const Text('Tentar novamente'),
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
              Icon(Icons.inbox_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 24),
              Text(
                'Nenhum unitizador disponível',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Não há unitizadores com OSs prontas para conferência nesta rua.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _carregarUnitizadores,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _unitizadores.length,
      itemBuilder: (context, index) {
        final unit = _unitizadores[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_shipping,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              'Unitizador ${unit['codunitizador'] ?? unit['codigo_barras']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${unit['qtd_itens'] ?? 0} itens para conferir'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Primeiro bipa o unitizador
              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.post('/wms/fase2/unitizador/${unit['codunitizador']}/bipar', {});
                
                if (!context.mounted) return;
                
                // Navega para tela de itens do unitizador
                final resultado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnitizadorItensScreen(
                      codunitizador: unit['codunitizador'],
                      rua: widget.rua,
                    ),
                  ),
                );
                
                if (resultado == true) {
                  _carregarUnitizadores();
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        );
      },
    );
  }
}
