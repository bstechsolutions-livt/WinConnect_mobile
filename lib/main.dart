import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/widgets/theme_selector.dart';
import 'shared/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('user_data');
  
  runApp(
    const ProviderScope(
      child: WinConnectApp(),
    ),
  );
}

class WinConnectApp extends ConsumerWidget {
  const WinConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    
    return themeAsync.when(
      data: (themeMode) => MaterialApp(
        title: 'WinConnect Mobile',
        debugShowCheckedModeBanner: false,
        
        // Theme Configuration
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        
        home: authState.when(
          data: (user) => user != null 
              ? const DashboardScreen()
              : const LoginScreen(),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const LoginScreen(),
        ),
      ),
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stackTrace) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}

// Placeholder dashboard
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getUserDisplayName(User user) {
    // Mostrar nome ou email
    String displayName = user.name.isNotEmpty ? user.name : user.email;
    
    // Se for nome completo, pegar primeiro e último
    if (user.name.isNotEmpty && user.name.contains(' ')) {
      final nameParts = user.name.split(' ');
      displayName = '${nameParts.first} ${nameParts.last}';
    }
    
    return displayName;
  }

  String _getUserInitials(User user) {
    if (user.name.isNotEmpty) {
      final nameParts = user.name.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
      } else {
        return user.name.substring(0, 1).toUpperCase();
      }
    } else {
      return user.email.substring(0, 1).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // Diminuído de 70 para 60
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E88E5), // Azul mais suave
                const Color(0xFF1976D2), // Azul mais escuro
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Logo/Título à esquerda
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.widgets_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'WinConnect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Nome do usuário no centro-direita
                  authState.when(
                    data: (user) => user != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    _getUserInitials(user),
                                    style: const TextStyle(
                                      color: Color(0xFF1976D2),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getUserDisplayName(user),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Botões à direita
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const ThemeSelector(isAppBar: true),
                      ),
                      const SizedBox(width: 6),
                      Consumer(
                        builder: (context, ref, child) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              iconSize: 16,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Sair',
                              onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 100, color: Colors.blue),
            SizedBox(height: 16),
            Text('Bem-vindo ao WinConnect!', 
                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Dashboard será implementado aqui'),
          ],
        ),
      ),
    );
  }
}
