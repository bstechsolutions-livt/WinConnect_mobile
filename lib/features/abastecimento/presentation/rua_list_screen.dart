import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/rua_provider.dart';
import '../providers/minha_rua_provider.dart';
import '../../../shared/models/rua_model.dart';
import '../../../shared/providers/api_service_provider.dart';
import 'os_list_screen.dart';
import 'fase2/unitizador_list_screen.dart';
import 'fase2/carrinho_screen.dart';

class RuaListScreen extends ConsumerStatefulWidget {
  final int fase;
  final String faseNome;

  const RuaListScreen({super.key, required this.fase, required this.faseNome});

  @override
  ConsumerState<RuaListScreen> createState() => _RuaListScreenState();
}

class _RuaListScreenState extends ConsumerState<RuaListScreen> {
  int _itensNoCarrinho = 0;

  @override
  void initState() {
    super.initState();
    // Limpa rua atual ao entrar na tela de seleção de ruas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ruaAtualProvider.notifier).setRuaAtual(null);
    });
    // Carrega carrinho apenas para Fase 2
    if (widget.fase == 2) {
      _carregarCarrinho();
    }
  }

  Future<void> _carregarCarrinho() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/wms/fase2/meu-carrinho');

      if (!mounted) return;

      final carrinho = response['carrinho'] as List? ?? [];
      setState(() {
        _itensNoCarrinho = carrinho.length;
      });
    } catch (_) {}
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
                builder: (context) => UnitizadorListScreen(rua: next),
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
        actions: widget.fase == 2 && _itensNoCarrinho > 0
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Badge(
                      label: Text(
                        '$_itensNoCarrinho',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.orange,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CarrinhoScreen(),
                        ),
                      );
                      if (result == true && mounted) {
                        _carregarCarrinho();
                        ref.invalidate(ruaNotifierProvider(widget.fase));
                      }
                    },
                  ),
                ),
              ]
            : null,
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
                    // Botão ir para carrinho (Fase 2)
                    if (widget.fase == 2 && _itensNoCarrinho > 0) ...[
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CarrinhoScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            _carregarCarrinho();
                            ref.invalidate(ruaNotifierProvider(widget.fase));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shopping_cart_rounded,
                                size: 18,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ir para o Carrinho ($_itensNoCarrinho)',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    GestureDetector(
                      onTap: () {
                        ref.invalidate(ruaNotifierProvider(widget.fase));
                        if (widget.fase == 2) _carregarCarrinho();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
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

          // Obtém a rua alocada para marcar visualmente
          final minhaRuaAsync = ref.watch(
            minhaRuaNotifierProvider(widget.fase),
          );
          final ruaAlocada = minhaRuaAsync.valueOrNull?.rua;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: ruas.length + 1,
            itemBuilder: (context, index) {
              // Header com total de ruas
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(
                        'Selecione uma rua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${ruas.length} ruas',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final rua = ruas[index - 1];
              final isAlocada = ruaAlocada != null && rua.codigo == ruaAlocada;
              // Se está alocado em alguma rua, só permite clicar na rua alocada
              final podeClicar = ruaAlocada == null || isAlocada;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RuaCard(
                  rua: rua,
                  isAlocada: isAlocada,
                  enabled: podeClicar,
                  onTap: () async {
                    if (!podeClicar) return;
                    
                    try {
                      if (!context.mounted) return;

                      // Fase 1: Chama API para entrar na rua antes de navegar
                      // MAS só se NÃO estiver já alocado nessa rua
                      if (widget.fase == 1 && !isAlocada) {
                        // Mostra loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          final apiService = ref.read(apiServiceProvider);
                          await apiService.post(
                            '/wms/fase1/entrar-rua',
                            {'rua': rua.codigo},
                          );

                          if (!context.mounted) return;
                          Navigator.pop(context); // Remove loading
                        } catch (e) {
                          if (!context.mounted) return;
                          Navigator.pop(context); // Remove loading

                          // Extrai mensagem de erro da API
                          String mensagem = 'Erro ao entrar na rua';
                          final errorStr = e.toString();
                          
                          // Se o erro é "já está alocado na mesma rua", ignora e continua
                          if (errorStr.contains('rua_atual') || 
                              (errorStr.contains('já está alocado') && errorStr.contains(rua.codigo))) {
                            // Continua normalmente - já está na rua correta
                          } else {
                            if (errorStr.contains('message')) {
                              final match = RegExp(r'"message"\s*:\s*"([^"]+)"')
                                  .firstMatch(errorStr);
                              if (match != null) {
                                mensagem = match.group(1) ?? mensagem;
                              }
                            } else {
                              mensagem = errorStr.replaceAll('Exception: ', '');
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(mensagem),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }
                      }

                      // Atualiza rua atual e navega para tela correta da fase
                      ref
                          .read(ruaAtualProvider.notifier)
                          .setRuaAtual(rua.codigo);

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
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UnitizadorListScreen(rua: rua.codigo),
                          ),
                        );
                        // Atualiza lista ao voltar
                        if (mounted) {
                          ref.invalidate(ruaNotifierProvider(widget.fase));
                          _carregarCarrinho();
                        }
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
  final bool isAlocada;
  final bool enabled;

  const _RuaCard({
    required this.rua,
    required this.onTap,
    this.isAlocada = false,
    this.enabled = true,
  });

  @override
  State<_RuaCard> createState() => _RuaCardState();
}

class _RuaCardState extends State<_RuaCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.isAlocada ? Colors.orange : Colors.blue;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.enabled ? (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        } : null,
        onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isAlocada
                ? Colors.orange.withValues(alpha: 0.8)
                : (_isPressed
                      ? accentColor.withValues(alpha: 0.5)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.15))),
            width: widget.isAlocada ? 2 : 1,
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
        child: Stack(
          children: [
            // Badge "VOCÊ ESTÁ AQUI" para rua alocada
            if (widget.isAlocada)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_pin_circle,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'VOCÊ ESTÁ AQUI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Ícone da rua com gradiente
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.isAlocada
                          ? Icons.person_pin_circle
                          : Icons.location_on_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Nome da rua e informações
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.rua.nome,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 12,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.rua.quantidade} OSs pendentes',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${widget.rua.quantidade}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ], // Fecha Stack children
        ), // Fecha Stack
      ),
    ),
    );
  }
}
