import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/os_provider.dart';
import '../../../shared/models/os_model.dart';
import 'os_endereco_screen.dart';
import 'os_bipar_screen.dart';

class OsListScreen extends ConsumerStatefulWidget {
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
  ConsumerState<OsListScreen> createState() => _OsListScreenState();
}

class _OsListScreenState extends ConsumerState<OsListScreen> {
  bool _navegouParaOsEmAndamento = false;

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(osNotifierProvider(widget.fase, widget.rua));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.rua} - ${widget.faseNome}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(osNotifierProvider(widget.fase, widget.rua).notifier).refresh();
            },
          ),
        ],
      ),
      body: osAsync.when(
        data: (result) {
          // Se tem OS em andamento, navega direto para ela (uma única vez)
          if (result.osEmAndamento != null && !_navegouParaOsEmAndamento) {
            _navegouParaOsEmAndamento = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OsBiparScreen(
                    fase: widget.fase,
                    numos: result.osEmAndamento!,
                    faseNome: widget.faseNome,
                  ),
                ),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (result.ordens.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: result.ordens.length,
            itemBuilder: (context, index) {
              final os = result.ordens[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OsCard(
                  os: os,
                  onTap: os.podeExecutar ? () async {
                    // Navega para tela de endereço (5ª tela)
                    final resultado = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OsEnderecoScreen(
                          fase: widget.fase,
                          numos: os.numos,
                          faseNome: widget.faseNome,
                        ),
                      ),
                    );
                    
                    // Se retornou true, atualiza a lista
                    if (resultado == true) {
                      ref.read(osNotifierProvider(widget.fase, widget.rua).notifier).refresh();
                    }
                  } : null,
                ),
              );
            },
          );
        },
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
                  ref.read(osNotifierProvider(widget.fase, widget.rua).notifier).refresh();
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
  final VoidCallback? onTap;

  const _OsCard({
    required this.os,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, os.status);
    final podeExecutar = onTap != null;
    
    return Opacity(
      opacity: podeExecutar ? 1.0 : 0.5,
      child: Card(
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
                    if (!podeExecutar) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'BLOQUEADA',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
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