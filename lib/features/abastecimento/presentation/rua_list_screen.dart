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
            Navigator.push(
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0D1117) 
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey.shade800,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Fase ${widget.fase}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: widget.fase == 1 ? Colors.blue : Colors.green,
              ),
            ),
            Text(
              widget.faseNome,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey.shade900,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ruasAsync.when(
        data: (ruas) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          if (ruas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inbox_rounded,
                        size: 56,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nenhuma rua disponível',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.fase == 1
                          ? 'Não há OSs aguardando coleta no momento'
                          : 'Não há OSs aguardando conferência',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => ref.invalidate(ruaNotifierProvider(widget.fase)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Atualizar',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: ruas.length + 1,
            itemBuilder: (context, index) {
              // Header com total de ruas
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Text(
                        'Selecione uma rua',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${ruas.length} ruas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              final rua = ruas[index - 1];
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
                      Navigator.push(
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

class _RuaCard extends StatefulWidget {
  final Rua rua;
  final VoidCallback onTap;

  const _RuaCard({
    required this.rua,
    required this.onTap,
  });

  @override
  State<_RuaCard> createState() => _RuaCardState();
}

class _RuaCardState extends State<_RuaCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Colors.blue;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPressed 
                ? accentColor.withValues(alpha: 0.5)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isPressed 
                  ? accentColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: _isPressed ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone da rua com gradiente
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.2),
                      accentColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: accentColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 14),
              
              // Nome da rua e informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.rua.nome,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 14,
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.rua.quantidade} OSs pendentes',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Badge com quantidade + seta
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.rua.quantidade}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
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