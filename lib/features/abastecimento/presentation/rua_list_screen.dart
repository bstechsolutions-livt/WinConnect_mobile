import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/rua_provider.dart';
import '../../../shared/models/rua_model.dart';
import '../../../shared/providers/api_service_provider.dart';
import 'os_list_screen.dart';

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

    // Se já está em uma rua, navega automaticamente para lista de OSs
    ref.listen(ruaAtualProvider, (previous, next) {
      if (next != null && previous != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OsListScreen(
                fase: fase,
                rua: next,
                faseNome: faseNome,
              ),
            ),
          );
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Fase $fase - $faseNome'),
        centerTitle: true,
      ),
      body: ruasAsync.when(
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
                    
                    // Atualiza rua atual e navega para lista de OSs
                    ref.read(ruaAtualProvider.notifier).setRuaAtual(rua.codigo);
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OsListScreen(
                          fase: fase,
                          rua: rua.codigo,
                          faseNome: faseNome,
                        ),
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
          child: Row(
            children: [
              // Ícone da rua
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Nome da rua e informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rua.nome,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
              
              // Seta para entrar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge com quantidade
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${rua.quantidade}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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