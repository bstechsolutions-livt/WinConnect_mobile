import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/os_provider.dart';
import '../providers/os_detalhe_provider.dart';
import '../../../shared/models/os_model.dart';
import '../../../shared/providers/api_service_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/liberar_rua_dialog.dart';
import 'os_endereco_screen.dart';

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

  /// Mostra dialog quando usuário tenta voltar enquanto está na rua
  Future<bool> _onWillPop() async {
    // Apenas para Fase 1 (onde operador fica preso na rua)
    if (widget.fase != 1) {
      return true; // Permite voltar normalmente
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final resultado = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C2128) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Você está na Rua',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Você está alocado na Rua ${widget.rua}. O que deseja fazer?',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        actions: [
          // Continuar trabalhando
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'continuar'),
            child: const Text('Continuar Trabalhando'),
          ),
          // Menu principal
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'menu'),
            child: Text(
              'Menu Principal',
              style: TextStyle(color: Colors.blue.shade400),
            ),
          ),
          // Sair da rua
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'sair'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sair da Rua'),
          ),
        ],
      ),
    );

    if (!mounted) return false;

    switch (resultado) {
      case 'menu':
        // Volta até o menu principal (AbastecimentoScreen)
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      
      case 'sair':
        // Abre dialog de liberação com supervisor
        final apiService = ref.read(apiServiceProvider);
        final user = ref.read(authNotifierProvider).value;
        final liberado = await LiberarRuaDialog.mostrar(
          context: context,
          apiService: apiService,
          rua: widget.rua,
          matriculaOperador: user?.matricula,
        );
        if (liberado && mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return false;
      
      case 'continuar':
      default:
        return false; // Fica na tela
    }
  }

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(osNotifierProvider(widget.fase, widget.rua));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: widget.fase != 1, // Bloqueia pop automático apenas na Fase 1
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Já fez pop, não faz nada
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0D1117)
            : const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          onPressed: () => _onWillPop(),
        ),
        title: Column(
          children: [
            Text(
              'Rua ${widget.rua}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
            Text(
              widget.faseNome,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Botão Sair da Rua (apenas Fase 1)
          if (widget.fase == 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () async {
                  final apiService = ref.read(apiServiceProvider);
                  final user = ref.read(authNotifierProvider).value;
                  final liberado = await LiberarRuaDialog.mostrar(
                    context: context,
                    apiService: apiService,
                    rua: widget.rua,
                    matriculaOperador: user?.matricula,
                  );
                  if (liberado && mounted) {
                    Navigator.pop(context); // Volta para lista de ruas
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.exit_to_app_rounded,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                ref
                    .read(osNotifierProvider(widget.fase, widget.rua).notifier)
                    .refresh();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: osAsync.when(
        data: (result) {
          // Se tem OS em andamento e ainda não navegamos nesta sessão, navega direto
          if (result.osEmAndamento != null && !_navegouParaOsEmAndamento) {
            _navegouParaOsEmAndamento = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;

              // Navega para tela de endereço (que vai verificar se já bipou ou não)
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => OsEnderecoScreen(
                    fase: widget.fase,
                    numos: result.osEmAndamento!,
                    faseNome: widget.faseNome,
                  ),
                ),
              );

              // Quando retornar (bloqueou ou finalizou), atualiza a lista
              if (mounted) {
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) {
                  _navegouParaOsEmAndamento = false;
                  ref
                      .read(
                        osNotifierProvider(widget.fase, widget.rua).notifier,
                      )
                      .refresh();
                }
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          // Filtra OSs - considera podeExecutar E status (BLOQUEADA = não pode)
          final osExecutaveis = result.ordens
              .where(
                (os) =>
                    os.podeExecutar && os.status.toUpperCase() != 'BLOQUEADA',
              )
              .toList();
          final osBloqueadas = result.ordens
              .where(
                (os) =>
                    !os.podeExecutar || os.status.toUpperCase() == 'BLOQUEADA',
              )
              .toList();

          if (osExecutaveis.isEmpty && osBloqueadas.isEmpty) {
            return _buildEmptyState(context, isDark);
          }

          // Adiciona +1 no final para o espaço da barra inferior
          final totalBloqueadas = osBloqueadas.isNotEmpty
              ? 1 + osBloqueadas.length
              : 0;
          final itemCount =
              osExecutaveis.length +
              1 +
              totalBloqueadas +
              1; // +1 final para padding

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            // +1 header executáveis, +1 header bloqueadas, + cards bloqueadas, +1 bottom padding
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Último item = espaço para barra inferior
              if (index == itemCount - 1) {
                return SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 20,
                );
              }
              // Header das OSs disponíveis
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Text(
                        'Ordens de Serviço',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      if (osExecutaveis.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${osExecutaveis.length} disponíveis',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }

              // Cards de OS executáveis
              if (index <= osExecutaveis.length && osExecutaveis.isNotEmpty) {
                final os = osExecutaveis[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OsCard(
                    os: os,
                    isDark: isDark,
                    onTap: () => _navegarParaOs(os),
                    podeExecutar: true,
                  ),
                );
              }

              // Se não tem OSs executáveis, mostra mensagem
              if (osExecutaveis.isEmpty &&
                  index == 1 &&
                  osBloqueadas.isNotEmpty) {
                // Será tratado no próximo bloco
              }

              // Header das OSs bloqueadas
              final bloqueadasHeaderIndex = osExecutaveis.length + 1;
              if (index == bloqueadasHeaderIndex && osBloqueadas.isNotEmpty) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: osExecutaveis.isNotEmpty ? 24 : 0,
                    bottom: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${osBloqueadas.length} OSs aguardando',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Toque para solicitar autorização do supervisor',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Cards de OSs bloqueadas
              if (index > bloqueadasHeaderIndex && osBloqueadas.isNotEmpty) {
                final bloqueadaIndex = index - bloqueadasHeaderIndex - 1;
                if (bloqueadaIndex < osBloqueadas.length) {
                  final os = osBloqueadas[bloqueadaIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OsCardBloqueada(
                      os: os,
                      isDark: isDark,
                      onTap: () async {
                        final autorizado = await _mostrarDialogAutorizacao(
                          os.numos,
                        );
                        if (autorizado == true) {
                          _navegarParaOs(os);
                        }
                      },
                    ),
                  );
                }
              }

              return const SizedBox.shrink();
            },
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Carregando OSs...',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Erro ao carregar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    ref
                        .read(
                          osNotifierProvider(widget.fase, widget.rua).notifier,
                        )
                        .refresh();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tentar novamente',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  void _navegarParaOs(OrdemServico os) async {
    // Primeiro inicia a OS usando o provider (que trata erro de rua bloqueada)
    if (os.podeExecutar) {
      final result = await ref
          .read(osDetalheNotifierProvider(widget.fase, os.numos).notifier)
          .iniciarOs();

      if (!result.sucesso) {
        // Verifica se é erro de "preso em outra rua"
        if (result.presoEmOutraRua) {
          if (mounted) {
            _mostrarDialogPresoEmRua(
              result.ruaBloqueada ?? '',
              result.erro ?? '',
            );
          }
          return;
        }

        // Outros erros
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.erro ?? 'Erro ao iniciar OS'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    // Se não podeExecutar, o iniciar já foi chamado no dialog de autorização

    if (!mounted) return;

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
  }

  /// Mostra dialog informando que o operador está preso em outra rua
  void _mostrarDialogPresoEmRua(String rua, String mensagem) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rua Bloqueada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.location_on, color: Colors.orange[700], size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Rua $rua',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mensagem,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Finalize as OSs pendentes na Rua $rua ou solicite liberação ao supervisor.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Volta para a lista de ruas para o operador ir à rua correta
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'IR PARA RUA $rua',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _mostrarDialogAutorizacao(int numos) async {
    final matriculaController = TextEditingController();
    final senhaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorMessage;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.admin_panel_settings,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AUTORIZAÇÃO',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'OS $numos - Fora de ordem',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(sheetContext, false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Aviso
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Esta OS está fora da ordem de execução.\nÉ necessária autorização de um supervisor.',
                                style: TextStyle(
                                  color: Colors.amber[900],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Campo matrícula
                      TextFormField(
                        controller: matriculaController,
                        decoration: InputDecoration(
                          labelText: 'Matrícula do Supervisor',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a matrícula';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Campo senha
                      TextFormField(
                        controller: senhaController,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a senha';
                          }
                          return null;
                        },
                      ),

                      // Erro
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Botões
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.pop(sheetContext, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('CANCELAR'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }

                                      setSheetState(() {
                                        isLoading = true;
                                        errorMessage = null;
                                      });

                                      try {
                                        final apiService = ref.read(
                                          apiServiceProvider,
                                        );
                                        await apiService.post(
                                          '/wms/fase${widget.fase}/os/$numos/iniciar',
                                          {
                                            'autorizador_matricula': int.parse(
                                              matriculaController.text,
                                            ),
                                            'autorizador_senha':
                                                senhaController.text,
                                          },
                                        );

                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext, true);
                                        }
                                      } catch (e) {
                                        setSheetState(() {
                                          isLoading = false;
                                          errorMessage = e
                                              .toString()
                                              .replaceAll('Exception: ', '');
                                        });
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'AUTORIZAR',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 56,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tudo pronto!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todas as OSs desta rua foram concluídas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OsCard extends StatefulWidget {
  final OrdemServico os;
  final VoidCallback onTap;
  final bool podeExecutar;
  final bool isDark;

  const _OsCard({
    required this.os,
    required this.onTap,
    required this.podeExecutar,
    required this.isDark,
  });

  @override
  State<_OsCard> createState() => _OsCardState();
}

class _OsCardState extends State<_OsCard> {
  bool _isPressed = false;

  Color _getStatusColor(String status) {
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
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return 'PENDENTE';
      case 'FASE1_ANDAMENTO':
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.os.status);

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
          color: widget.isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPressed
                ? statusColor.withValues(alpha: 0.5)
                : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.15)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? statusColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.08),
              blurRadius: _isPressed ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: OS + Status
              Row(
                children: [
                  Text(
                    'OS ${widget.os.numos}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark
                          ? Colors.white
                          : Colors.grey.shade900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(widget.os.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Ordem + Código
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${widget.os.ordem}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Cód: ${widget.os.codprod}',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.isDark
                          ? Colors.white54
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informações do produto
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 16,
                      color: widget.isDark
                          ? Colors.white54
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.os.descricao,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.isDark
                            ? Colors.white
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Quantidade e Origem
              Row(
                children: [
                  // Quantidade
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.straighten_rounded,
                          size: 14,
                          color: widget.isDark
                              ? Colors.white38
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Quantidade: ${widget.os.quantidade.toStringAsFixed(0)} un',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Endereço origem
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: widget.isDark
                        ? Colors.white38
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Origem: ${widget.os.enderecoOrigem}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? Colors.white54
                            : Colors.grey.shade600,
                      ),
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

/// Card compacto para OSs bloqueadas
class _OsCardBloqueada extends StatelessWidget {
  final OrdemServico os;
  final VoidCallback onTap;
  final bool isDark;

  const _OsCardBloqueada({
    required this.os,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.orange.withValues(alpha: 0.08)
              : Colors.orange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone de cadeado
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock_rounded, size: 16, color: Colors.orange),
            ),

            const SizedBox(width: 12),

            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'OS ${os.numos}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${os.ordem}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    os.descricao,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Seta indicando que pode clicar
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.orange.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
