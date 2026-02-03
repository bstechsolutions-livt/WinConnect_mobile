import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/app_update_info.dart';
import '../providers/app_update_provider.dart';

/// Tela de atualização (substitui o dialog para melhor UX em telas pequenas)
class UpdateScreen extends ConsumerWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback? onSkip;
  final VoidCallback? onUpdate;

  const UpdateScreen({
    super.key,
    required this.updateInfo,
    this.onSkip,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = ref.watch(appUpdateNotifierProvider);

    return PopScope(
      canPop:
          !updateInfo.forceUpdate &&
          !progress.isDownloading &&
          !progress.isInstalling,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Botão Pular no topo direito (se não for obrigatório e não estiver baixando)
                if (!updateInfo.forceUpdate &&
                    !progress.isDownloading &&
                    !progress.isInstalling)
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSkip?.call();
                      },
                      child: Text(
                        'Pular',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 40),

                const Spacer(),

                // Conteúdo central
                _buildContent(context, ref, progress, theme),

                const Spacer(),

                // Botões na parte inferior
                _buildBottomButtons(context, ref, progress, theme),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UpdateProgress progress,
    ThemeData theme,
  ) {
    // Se estiver baixando ou instalando, mostra progresso
    if (progress.isDownloading || progress.isInstalling) {
      return _buildProgressContent(context, progress, theme);
    }

    // Se teve erro ou foi cancelado
    if (progress.hasError || progress.status == UpdateStatus.cancelled) {
      return _buildErrorContent(context, ref, progress, theme);
    }

    // Se instalou com sucesso
    if (progress.status == UpdateStatus.installed) {
      return _buildSuccessContent(context, theme);
    }

    // Estado inicial - mostra info da atualização
    return _buildUpdateInfo(context, theme);
  }

  Widget _buildUpdateInfo(BuildContext context, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícone
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.system_update_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

        const SizedBox(height: 24),

        // Título
        Text(
          updateInfo.forceUpdate
              ? 'Atualização Obrigatória'
              : 'Nova Versão Disponível',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Versão
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'v${updateInfo.latestVersion}',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),

        if (updateInfo.forceUpdate) ...[
          const SizedBox(height: 16),
          Text(
            'Esta atualização é necessária para continuar usando o app.',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildProgressContent(
    BuildContext context,
    UpdateProgress progress,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícone animado
        Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                progress.isInstalling
                    ? Icons.install_mobile_rounded
                    : Icons.cloud_download_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 600.ms,
            )
            .then()
            .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(1, 1),
              duration: 600.ms,
            ),

        const SizedBox(height: 24),

        // Título
        Text(
          progress.isInstalling ? 'Instalando...' : 'Baixando Atualização',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        // Barra de progresso
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.progress,
            minHeight: 10,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),

        const SizedBox(height: 12),

        // Porcentagem
        Text(
          '${progress.progressPercent}%',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(
    BuildContext context,
    WidgetRef ref,
    UpdateProgress progress,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            progress.status == UpdateStatus.cancelled
                ? Icons.cancel_rounded
                : Icons.error_rounded,
            size: 48,
            color: progress.status == UpdateStatus.cancelled
                ? Colors.orange
                : Colors.red,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          progress.status == UpdateStatus.cancelled
              ? 'Download Cancelado'
              : 'Erro na Atualização',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        if (progress.error != null) ...[
          const SizedBox(height: 12),
          Text(
            progress.error!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessContent(BuildContext context, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 48,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Atualização Concluída!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'O app será reiniciado automaticamente.',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    WidgetRef ref,
    UpdateProgress progress,
    ThemeData theme,
  ) {
    // Se estiver baixando
    if (progress.isDownloading) {
      if (!updateInfo.forceUpdate) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              ref.read(appUpdateNotifierProvider.notifier).cancelUpdate();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // Se estiver instalando
    if (progress.isInstalling || progress.status == UpdateStatus.installed) {
      return const SizedBox.shrink();
    }

    // Se teve erro ou foi cancelado
    if (progress.hasError || progress.status == UpdateStatus.cancelled) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.read(appUpdateNotifierProvider.notifier).reset();
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tentar Novamente'),
            ),
          ),
          if (!updateInfo.forceUpdate) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Voltar',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Estado inicial - botão de atualizar
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          onUpdate?.call();
        },
        icon: const Icon(Icons.download_rounded),
        label: const Text('Atualizar Agora'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Helper para navegar para a tela de atualização
class UpdateScreenHelper {
  /// Verifica e mostra tela de atualização se disponível
  static Future<void> checkAndShowUpdate(
    BuildContext context,
    WidgetRef ref, {
    bool showOnlyIfAvailable = true,
  }) async {
    final updateInfo = await ref.read(checkAppUpdateProvider.future);

    if (!updateInfo.hasUpdate && showOnlyIfAvailable) return;

    if (!context.mounted) return;

    if (updateInfo.hasUpdate) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => UpdateScreen(
            updateInfo: updateInfo,
            onUpdate: () => _startUpdate(ctx, ref, updateInfo),
          ),
        ),
      );
    }
  }

  /// Inicia o processo de atualização
  static void _startUpdate(
    BuildContext context,
    WidgetRef ref,
    AppUpdateInfo updateInfo,
  ) {
    if (updateInfo.downloadUrl == null) return;

    // Inicia o download
    ref
        .read(appUpdateNotifierProvider.notifier)
        .startUpdate(
          updateInfo.downloadUrl!,
          sha256Checksum: updateInfo.sha256Checksum,
        );
  }
}
