import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/rua_provider.dart';
import '../../../shared/models/rua_model.dart';
import '../../../shared/providers/api_service_provider.dart';

class RuaListScreen extends ConsumerWidget {
  final int fase;
  final String faseNome;

  const RuaListScreen({
    super.key,
    required this.fase,
    required this.faseNome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruasAsync = ref.watch(ruaNotifierProvider(fase));

    return Scaffold(
      appBar: AppBar(
        title: Text('Fase $fase - $faseNome'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Lista de ruas
          Expanded(
            child: ruasAsync.when(
              data: (ruas) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ruas.length,
                itemBuilder: (context, index) {
                  final rua = ruas[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RuaCard(
                      rua: rua,
                      onTap: () async {
                        // Entra diretamente na rua selecionada
                        try {
                          final apiService = ref.read(apiServiceProvider);
                          await apiService.post('/abastecimento/fase$fase/ruas/${rua.codigo}/entrar', {});
                          
                          if (!context.mounted) return;
                          
                          // Navegar para lista de OSs da rua
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Entrada na ${rua.nome} registrada!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao entrar na rua: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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
                      'Erro ao carregar ruas',
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
                        ref.invalidate(ruaNotifierProvider(fase));
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Botão de ação
          Consumer(
            builder: (context, ref, child) {
              final ruas = ref.watch(ruaNotifierProvider(fase)).value ?? [];
              final selecionadas = ruas.where((r) => r.selecionada).toList();
              
              if (selecionadas.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () {
                    _mostrarResumoSelecao(context, selecionadas);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Continuar com ${selecionadas.length} rua${selecionadas.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _mostrarResumoSelecao(BuildContext context, List<Rua> selecionadas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ruas Selecionadas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fase $fase - $faseNome'),
            const SizedBox(height: 12),
            ...selecionadas.map(
              (rua) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text('${rua.nome} (${rua.quantidade} OSs)'),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Iniciando abastecimento de ${selecionadas.length} ruas',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _RuaCard extends StatelessWidget {
  final Rua rua;
  final VoidCallback onTap;

  const _RuaCard({
    required this.rua,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = rua.selecionada;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
          ),
          child: Row(
            children: [
              // Checkbox/círculo de seleção
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Nome da rua
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rua.nome,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rua.quantidade} OSs pendentes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Quantidade destacada
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${rua.quantidade}',
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}