import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/theme_provider.dart';

class ThemeSelector extends ConsumerWidget {
  final bool isAppBar;
  
  const ThemeSelector({super.key, this.isAppBar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    
    return themeState.when(
      data: (themeMode) => PopupMenuButton<ThemeMode>(
        icon: Icon(
          _getThemeIcon(themeMode),
          color: isAppBar ? Colors.white : null,
          size: isAppBar ? 12 : 24,
        ),
        iconSize: isAppBar ? 12 : 24,
        padding: EdgeInsets.zero,
        splashRadius: isAppBar ? 14 : null,
        constraints: isAppBar ? const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ) : null,
        tooltip: 'Aparência',
        onSelected: (mode) {
          ref.read(themeNotifierProvider.notifier).setThemeMode(mode);
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: ThemeMode.system,
            child: Row(
              children: [
                const Icon(Icons.brightness_auto),
                const SizedBox(width: 12),
                const Text('Sistema'),
                if (themeMode == ThemeMode.system) ...[
                  const Spacer(),
                  const Icon(Icons.check, color: Colors.blue),
                ],
              ],
            ),
          ),
          PopupMenuItem(
            value: ThemeMode.light,
            child: Row(
              children: [
                const Icon(Icons.light_mode),
                const SizedBox(width: 12),
                const Text('Claro'),
                if (themeMode == ThemeMode.light) ...[
                  const Spacer(),
                  const Icon(Icons.check, color: Colors.blue),
                ],
              ],
            ),
          ),
          PopupMenuItem(
            value: ThemeMode.dark,
            child: Row(
              children: [
                const Icon(Icons.dark_mode),
                const SizedBox(width: 12),
                const Text('Escuro'),
                if (themeMode == ThemeMode.dark) ...[
                  const Spacer(),
                  const Icon(Icons.check, color: Colors.blue),
                ],
              ],
            ),
          ),
        ],
      ),
      loading: () => const Icon(Icons.brightness_auto),
      error: (error, stackTrace) => const Icon(Icons.brightness_auto),
    );
  }
  
  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}