import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final currentTheme = ref.watch(themeNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(
              currentTheme == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home,
              size: 100,
              color: Colors.blue,
            )
                .animate()
                .scale(duration: AppConstants.mediumAnimation)
                .then()
                .shimmer(duration: 2.seconds),
            
            const SizedBox(height: 32),
            
            Text(
              'Welcome to ${AppConstants.appName}!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: AppConstants.mediumAnimation, delay: 200.ms)
                .slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 16),
            
            Text(
              'Modern Flutter Stack with Riverpod, Go Router & More',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: AppConstants.mediumAnimation, delay: 400.ms)
                .slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 48),
            
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _MenuButton(
                  icon: Icons.login,
                  label: 'Login',
                  onTap: () => context.push(AppConstants.loginRoute),
                ),
                _MenuButton(
                  icon: Icons.person_add,
                  label: 'Register',
                  onTap: () => context.push(AppConstants.registerRoute),
                ),
                _MenuButton(
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () => context.push(AppConstants.profileRoute),
                ),
                _MenuButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => context.push(AppConstants.settingsRoute),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: AppConstants.mediumAnimation, delay: 600.ms)
                .slideY(begin: 0.5, end: 0),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}