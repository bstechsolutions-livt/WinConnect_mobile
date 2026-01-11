import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'rua_list_screen.dart';
import 'os_endereco_screen.dart';
import '../../../shared/providers/auth_provider.dart';
import '../providers/os_ativa_provider.dart';

class AbastecimentoScreen extends ConsumerStatefulWidget {
  const AbastecimentoScreen({super.key});

  @override
  ConsumerState<AbastecimentoScreen> createState() => _AbastecimentoScreenState();
}

class _AbastecimentoScreenState extends ConsumerState<AbastecimentoScreen> {
  bool _verificandoOsAtiva = true;
  bool _navegouParaOsAtiva = false;

  @override
  void initState() {
    super.initState();
    _verificarOsAtiva();
  }

  Future<void> _verificarOsAtiva() async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.value;
    
    if (user?.matricula == null) {
      setState(() => _verificandoOsAtiva = false);
      return;
    }

    // Consulta se tem OS ativa
    final osAtiva = await ref.read(osAtivaProvider(user!.matricula!).future);
    
    if (osAtiva != null && mounted && !_navegouParaOsAtiva) {
      _navegouParaOsAtiva = true;
      // Tem OS ativa, navega para tela de endereço
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OsEnderecoScreen(
            fase: osAtiva.fase,
            numos: osAtiva.numos,
            faseNome: osAtiva.fase == 1 ? 'Empilhadeira' : 'Auxiliar',
          ),
        ),
      );
    } else {
      setState(() => _verificandoOsAtiva = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verificandoOsAtiva) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Abastecimento'),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando OS em andamento...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abastecimento'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Opções de Fase
            Expanded(
              child: Column(
                children: [
                  // Fase 1
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: _FaseCard(
                        faseNumber: 1,
                        title: 'Fase 1',
                        description: 'Empilhadeira',
                        icon: Icons.looks_one_rounded,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RuaListScreen(
                                fase: 1,
                                faseNome: 'Empilhadeira',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Fase 2
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: _FaseCard(
                        faseNumber: 2,
                        title: 'Fase 2',
                        description: 'Auxiliar',
                        icon: Icons.looks_two_rounded,
                        color: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RuaListScreen(
                                fase: 2,
                                faseNome: 'Auxiliar',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaseCard extends StatelessWidget {
  final int faseNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FaseCard({
    required this.faseNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tocar para continuar',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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