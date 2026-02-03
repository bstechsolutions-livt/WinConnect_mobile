import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/app_update_info.dart';
import '../providers/app_update_provider.dart';

/// Dialog de atualização disponível
class UpdateAvailableDialog extends ConsumerWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback? onLater;
  final VoidCallback? onUpdate;

  const UpdateAvailableDialog({
    super.key,
    required this.updateInfo,
    this.onLater,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone pequeno
            Icon(
              Icons.system_update_rounded,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            
            const SizedBox(height: 8),
            
            // Título simples
            Text(
              updateInfo.forceUpdate
                  ? 'Atualização Obrigatória'
                  : 'Atualização Disponível',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            // Versão
            Text(
              'v${updateInfo.latestVersion}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botão Atualizar
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onUpdate?.call();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Atualizar'),
              ),
            ),
            
            // "Depois" só se não for obrigatório
            if (!updateInfo.forceUpdate) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onLater?.call();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                child: Text(
                  'Depois',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    
    while (size > 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}

/// Dialog de progresso do download/instalação
class UpdateProgressDialog extends ConsumerWidget {
  final bool canCancel;

  const UpdateProgressDialog({
    super.key,
    this.canCancel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(appUpdateNotifierProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: canCancel && !progress.isInstalling,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone animado
              _buildStatusIcon(progress, theme),
              
              const SizedBox(height: 20),
              
              // Título
              Text(
                _getStatusTitle(progress),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Mensagem
              if (progress.message != null)
                Text(
                  progress.message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              
              // Erro
              if (progress.hasError && progress.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          progress.error!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Barra de progresso
              if (progress.isDownloading || progress.isInstalling) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.progress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${progress.progressPercent}%',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Botões
              if (progress.hasError || progress.status == UpdateStatus.cancelled)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fechar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        ref.read(appUpdateNotifierProvider.notifier).reset();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                )
              else if (canCancel && progress.isDownloading)
                TextButton(
                  onPressed: () {
                    ref.read(appUpdateNotifierProvider.notifier).cancelUpdate();
                  },
                  child: const Text('Cancelar'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(UpdateProgress progress, ThemeData theme) {
    IconData icon;
    Color color;
    bool animate = false;

    switch (progress.status) {
      case UpdateStatus.downloading:
        icon = Icons.cloud_download_rounded;
        color = theme.colorScheme.primary;
        animate = true;
        break;
      case UpdateStatus.installing:
        icon = Icons.install_mobile_rounded;
        color = theme.colorScheme.secondary;
        animate = true;
        break;
      case UpdateStatus.installed:
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case UpdateStatus.error:
        icon = Icons.error_rounded;
        color = theme.colorScheme.error;
        break;
      case UpdateStatus.cancelled:
        icon = Icons.cancel_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.update_rounded;
        color = theme.colorScheme.primary;
    }

    Widget iconWidget = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48, color: color),
    );

    if (animate) {
      iconWidget = iconWidget
          .animate(onPlay: (controller) => controller.repeat())
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
          );
    }

    return iconWidget;
  }

  String _getStatusTitle(UpdateProgress progress) {
    switch (progress.status) {
      case UpdateStatus.downloading:
        return 'Baixando Atualização';
      case UpdateStatus.installing:
        return 'Instalando...';
      case UpdateStatus.installed:
        return 'Atualização Concluída!';
      case UpdateStatus.error:
        return 'Erro na Atualização';
      case UpdateStatus.cancelled:
        return 'Download Cancelado';
      default:
        return 'Atualizando...';
    }
  }
}

/// Helper para exibir os dialogs de atualização
class UpdateDialogHelper {
  /// Verifica e mostra dialog de atualização se disponível
  static Future<void> checkAndShowUpdate(
    BuildContext context,
    WidgetRef ref, {
    bool showOnlyIfAvailable = true,
  }) async {
    final updateInfo = await ref.read(checkAppUpdateProvider.future);
    
    if (!updateInfo.hasUpdate && showOnlyIfAvailable) return;
    
    if (!context.mounted) return;

    if (updateInfo.hasUpdate) {
      await showDialog(
        context: context,
        barrierDismissible: !updateInfo.forceUpdate,
        builder: (context) => UpdateAvailableDialog(
          updateInfo: updateInfo,
          onUpdate: () => _startUpdate(context, ref, updateInfo),
        ),
      );
    }
  }

  /// Inicia o processo de atualização
  static Future<void> _startUpdate(
    BuildContext context,
    WidgetRef ref,
    AppUpdateInfo updateInfo,
  ) async {
    if (updateInfo.downloadUrl == null) return;

    // Inicia o download
    ref.read(appUpdateNotifierProvider.notifier).startUpdate(
      updateInfo.downloadUrl!,
      sha256Checksum: updateInfo.sha256Checksum,
    );

    // Mostra dialog de progresso
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateProgressDialog(
          canCancel: !updateInfo.forceUpdate,
        ),
      );
    }
  }
}
