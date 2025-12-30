import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/os_provider.dart';
import '../../../shared/models/os_model.dart';

class OsListScreen extends ConsumerWidget {
  final int fase;
  final String rua;
  final String faseNome;

  const OsListScreen({
    super.key,
    required this.fase,
    required this.rua,
    required this.faseNome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final osAsync = ref.watch(osNotifierProvider(fase, rua));

    return Scaffold(
      appBar: AppBar(
        title: Text('$rua - $faseNome'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(osNotifierProvider(fase, rua).notifier).refresh();
            },
          ),
        ],
      ),
      body: osAsync.when(
        data: (osList) => osList.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: osList.length,
                itemBuilder: (context, index) {
                  final os = osList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OsCard(
                      os: os,
                      onTap: () {
                        // TODO: Navegar para detalhes da OS
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('OS ${os.numos} - Em desenvolvimento'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
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
              Text(
                'Erro ao carregar OSs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(osNotifierProvider(fase, rua).notifier).refresh();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma OS pendente',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Todas as ordens de serviço desta rua foram concluídas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OsCard extends StatelessWidget {
  final OrdemServico os;
  final VoidCallback onTap;

  const _OsCard({
    required this.os,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, os.status);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: OS + Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'OS ${os.numos}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(os.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informações do produto
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      os.produto,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Quantidade
              Row(
                children: [
                  Icon(
                    Icons.straighten,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quantidade: ${os.quantidade.toStringAsFixed(0)} un',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Endereços
              Row(
                children: [
                  Icon(
                    Icons.route,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${os.enderecoOrigem} → ${os.enderecoDestino}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              
              // Divergência (se houver)
              if (os.divergencia != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          os.divergencia!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontSize: 12,
                          ),
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
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return Colors.orange;
      case 'FASE1_ANDAMENTO':
      case 'FASE2_ANDAMENTO':
        return Colors.blue;
      case 'CONCLUIDA':
        return Colors.green;
      case 'BLOQUEADA':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return 'PENDENTE';
      case 'FASE1_ANDAMENTO':
        return 'EM ANDAMENTO';
      case 'FASE2_ANDAMENTO':
        return 'EM ANDAMENTO';
      case 'CONCLUIDA':
        return 'CONCLUÍDA';
      case 'BLOQUEADA':
        return 'BLOQUEADA';
      default:
        return status;
    }
  }
}