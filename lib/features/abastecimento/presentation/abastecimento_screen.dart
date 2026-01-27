import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../shared/providers/app_info_provider.dart';
import 'rua_list_screen.dart';
import 'os_endereco_screen.dart';
import '../../../shared/providers/auth_provider.dart';
import '../providers/os_ativa_provider.dart';
import '../providers/minha_rua_provider.dart';

class AbastecimentoScreen extends ConsumerStatefulWidget {
  const AbastecimentoScreen({super.key});

  @override
  ConsumerState<AbastecimentoScreen> createState() =>
      _AbastecimentoScreenState();
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

    try {
      // Consulta se tem OS ativa
      final osAtiva = await ref.read(osAtivaProvider(user!.matricula!).future);

      if (osAtiva != null && mounted && !_navegouParaOsAtiva) {
        _navegouParaOsAtiva = true;

        final faseNome = osAtiva.fase == 1 ? 'Empilhadeira' : 'Auxiliar';

        // SEMPRE volta para tela de bipar endereço (recomeça do início)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OsEnderecoScreen(
              fase: osAtiva.fase,
              numos: osAtiva.numos,
              faseNome: faseNome,
            ),
          ),
        );
      } else {
        setState(() => _verificandoOsAtiva = false);
      }
    } catch (e) {
      // Erro de conexão - mostra mensagem e não deixa continuar
      if (mounted) {
        setState(() => _verificandoOsAtiva = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Constrói banner mostrando em qual rua o operador está alocado
  Widget _buildMinhaRuaBanner() {
    // Verifica a rua para fase 1 (principal)
    final minhaRuaAsync = ref.watch(minhaRuaNotifierProvider(1));

    return minhaRuaAsync.when(
      data: (info) {
        if (!info.estaEmRua) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.15),
                Colors.blue.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Você está alocado na',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Rua ${info.rua}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    if (info.osPendentes > 0)
                      Text(
                        '${info.osPendentes} OSs pendentes',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white60 : Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ALOCADO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_verificandoOsAtiva) {
      return Scaffold(
        appBar: AppBar(title: const Text('Abastecimento'), centerTitle: true),
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Consumer(
                builder: (context, ref, _) {
                  final versionAsync = ref.watch(appVersionProvider);
                  return Text(
                    'v${versionAsync.valueOrNull ?? "..."}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner de rua alocada (se houver)
              _buildMinhaRuaBanner(),

              // Verifica se está alocado em rua da Fase 1
              Builder(
                builder: (context) {
                  final minhaRuaAsync = ref.watch(minhaRuaNotifierProvider(1));
                  final estaAlocadoFase1 = minhaRuaAsync.valueOrNull?.estaEmRua ?? false;

                  return Column(
                    children: [
                      // Fase 1
                      _FaseCard(
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

                      const SizedBox(height: 12),

                      // Fase 2 - desabilitada se alocado na Fase 1
                      _FaseCard(
                        faseNumber: 2,
                        title: 'Fase 2',
                        description: estaAlocadoFase1 
                            ? 'Finalize a Fase 1 primeiro'
                            : 'Auxiliar',
                        icon: Icons.looks_two_rounded,
                        color: Colors.green,
                        enabled: !estaAlocadoFase1,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RuaListScreen(fase: 2, faseNome: 'Auxiliar'),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaseCard extends StatefulWidget {
  final int faseNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _FaseCard({
    required this.faseNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<_FaseCard> createState() => _FaseCardState();
}

class _FaseCardState extends State<_FaseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.5,
        child: GestureDetector(
          onTapDown: widget.enabled ? (_) {
            setState(() => _isPressed = true);
            _controller.forward();
          } : null,
          onTapUp: widget.enabled ? (_) {
            setState(() => _isPressed = false);
            _controller.reverse();
            widget.onTap();
          } : null,
          onTapCancel: widget.enabled ? () {
            setState(() => _isPressed = false);
            _controller.reverse();
          } : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      widget.color.withValues(alpha: 0.25),
                      widget.color.withValues(alpha: 0.08),
                    ]
                  : [
                      widget.color.withValues(alpha: 0.15),
                      widget.color.withValues(alpha: 0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: widget.color.withValues(alpha: _isPressed ? 0.6 : 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _isPressed ? 0.25 : 0.12),
                blurRadius: _isPressed ? 16 : 8,
                spreadRadius: _isPressed ? 1 : 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Decoração de fundo
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Conteúdo principal
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Ícone à esquerda
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color,
                            widget.color.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.faseNumber}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Textos
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.color,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            widget.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botão Iniciar à direita
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Iniciar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
