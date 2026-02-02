import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/app_update_provider.dart';
import 'update_dialog.dart';

/// Widget que envolve o app e verifica atualizações automaticamente
/// 
/// Deve ser usado como wrapper do widget principal após o login
class UpdateCheckerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final bool checkOnStart;
  final Duration checkInterval;

  const UpdateCheckerWrapper({
    super.key,
    required this.child,
    this.checkOnStart = true,
    this.checkInterval = const Duration(hours: 1),
  });

  @override
  ConsumerState<UpdateCheckerWrapper> createState() => _UpdateCheckerWrapperState();
}

class _UpdateCheckerWrapperState extends ConsumerState<UpdateCheckerWrapper> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    if (widget.checkOnStart) {
      // Aguarda o widget estar montado antes de verificar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUpdates();
      });
    }
  }

  Future<void> _checkForUpdates() async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      await UpdateDialogHelper.checkAndShowUpdate(context, ref);
    } catch (e) {
      debugPrint('Erro ao verificar atualizações: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Mixin para adicionar verificação de atualização em qualquer tela
mixin UpdateCheckerMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _updateChecked = false;

  /// Verifica atualizações (chame no initState após super.initState())
  void checkForUpdates({bool force = false}) {
    if (_updateChecked && !force) return;
    _updateChecked = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await UpdateDialogHelper.checkAndShowUpdate(context, ref);
      } catch (e) {
        debugPrint('Erro ao verificar atualizações: $e');
      }
    });
  }
}

/// Widget simples para exibir badge de atualização disponível
class UpdateBadge extends ConsumerWidget {
  final Widget child;
  final bool showDot;

  const UpdateBadge({
    super.key,
    required this.child,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(checkAppUpdateProvider);

    return updateAsync.when(
      data: (info) {
        if (!info.hasUpdate) return child;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (showDot)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: info.forceUpdate ? Colors.red : Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => child,
      error: (_, _) => child,
    );
  }
}

/// Botão de verificar atualização manual
class CheckUpdateButton extends ConsumerWidget {
  final bool iconOnly;

  const CheckUpdateButton({
    super.key,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(checkAppUpdateProvider);

    return updateAsync.when(
      data: (info) {
        if (iconOnly) {
          return IconButton(
            onPressed: () => _onPressed(context, ref, info),
            icon: UpdateBadge(
              child: Icon(
                info.hasUpdate ? Icons.system_update : Icons.check_circle_outline,
                color: info.hasUpdate ? Colors.orange : Colors.green,
              ),
            ),
            tooltip: info.hasUpdate ? 'Atualização disponível' : 'App atualizado',
          );
        }

        return ListTile(
          leading: UpdateBadge(
            child: Icon(
              info.hasUpdate ? Icons.system_update : Icons.check_circle_outline,
              color: info.hasUpdate ? Colors.orange : Colors.green,
            ),
          ),
          title: Text(
            info.hasUpdate ? 'Atualização Disponível' : 'App Atualizado',
          ),
          subtitle: Text(
            info.hasUpdate
                ? 'Nova versão ${info.latestVersion} disponível'
                : 'Você está na versão mais recente',
          ),
          trailing: info.hasUpdate
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : null,
          onTap: () => _onPressed(context, ref, info),
        );
      },
      loading: () => iconOnly
          ? const IconButton(
              onPressed: null,
              icon: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Verificando atualizações...'),
            ),
      error: (_, _) => iconOnly
          ? IconButton(
              onPressed: () => ref.invalidate(checkAppUpdateProvider),
              icon: const Icon(Icons.refresh),
              tooltip: 'Tentar novamente',
            )
          : ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('Erro ao verificar'),
              trailing: TextButton(
                onPressed: () => ref.invalidate(checkAppUpdateProvider),
                child: const Text('Tentar'),
              ),
            ),
    );
  }

  void _onPressed(BuildContext context, WidgetRef ref, updateInfo) {
    if (updateInfo.hasUpdate) {
      UpdateDialogHelper.checkAndShowUpdate(context, ref, showOnlyIfAvailable: false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você já está na versão mais recente!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
