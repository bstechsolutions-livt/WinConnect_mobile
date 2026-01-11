import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/rua_provider.dart';
import '../../../shared/models/rua_model.dart';
import 'os_list_screen.dart';
import 'fase2/unitizador_list_screen.dart';

class RuaListScreen extends ConsumerStatefulWidget {
  final int fase;
  final String faseNome;

  const RuaListScreen({
    super.key,
    required this.fase,
    required this.faseNome,
  });

  @override
  ConsumerState<RuaListScreen> createState() => _RuaListScreenState();
}

class _RuaListScreenState extends ConsumerState<RuaListScreen> {
  @override
  void initState() {
    super.initState();
    // Limpa rua atual ao entrar na tela de seleção de ruas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ruaAtualProvider.notifier).setRuaAtual(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ruasAsync = ref.watch(ruaNotifierProvider(widget.fase));

    // Se já está em uma rua, navega automaticamente para tela correta da fase
    ref.listen(ruaAtualProvider, (previous, next) {
      if (next != null && previous != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.fase == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OsListScreen(
                  fase: widget.fase,
                  rua: next,
                  faseNome: widget.faseNome,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UnitizadorListScreen(
                  rua: next,
                ),
              ),
            );
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Fase ${widget.fase} - ${widget.faseNome}'),
        centerTitle: true,
      ),
      body: ruasAsync.when(
        data: (ruas) {
          if (ruas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nenhuma rua com OS pendente',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.fase == 1
                          ? 'Não há ordens de serviço aguardando coleta no momento.\n\nQuando houver OSs pendentes, as ruas aparecerão aqui.'
                          : 'Não há ordens de serviço aguardando conferência no momento.\n\nQuando a Fase 1 for concluída, as ruas aparecerão aqui.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(ruaNotifierProvider(widget.fase)),
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
            itemCount: ruas.length,
            itemBuilder: (context, index) {
              final rua = ruas[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RuaCard(
                  rua: rua,
                onTap: () async {
                  // Navega diretamente para a lista de OSs da rua
                  try {
                    if (!context.mounted) return;
                    
                    // Atualiza rua atual e navega para tela correta da fase
                    ref.read(ruaAtualProvider.notifier).setRuaAtual(rua.codigo);
                    
                    if (widget.fase == 1) {
                      // Fase 1: Lista de OSs
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OsListScreen(
                            fase: widget.fase,
                            rua: rua.codigo,
                            faseNome: widget.faseNome,
                          ),
                        ),
                      );
                    } else {
                      // Fase 2: Lista de Unitizadores
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UnitizadorListScreen(
                            rua: rua.codigo,
                          ),
                        ),
                      );
                    }
                    
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
                  ref.invalidate(ruaNotifierProvider(widget.fase));
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