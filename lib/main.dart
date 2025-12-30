import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/auth_provider.dart';

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
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WinConnect'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
              );
            },
          ),
        ],
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
