import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/client_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/abastecimento/presentation/abastecimento_screen.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/auth_provider.dart';
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
        title: ClientConfig.current.name,
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

// Dashboard moderno
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header moderno
            _buildHeader(context, ref, authState, isDark),
            
            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saudação
                    authState.when(
                      data: (user) => user != null
                          ? _buildGreeting(context, user, isDark)
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Título da seção
                    Text(
                      'Módulos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Card de Abastecimento
                    _ModernMenuCard(
                      icon: Icons.inventory_2_rounded,
                      title: 'Abastecimento',
                      subtitle: 'Gestão de estoque WMS',
                      gradientColors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AbastecimentoScreen(),
                          ),
                        );
                      },
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, AsyncValue<User?> authState, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo da empresa
          _buildLogo(context, isDark),
          
          const Spacer(),
          
          // Botões de ação
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.brightness_6_rounded,
                isDark: isDark,
                onTap: () {
                  ref.read(themeNotifierProvider.notifier).toggleTheme();
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.logout_rounded,
                isDark: isDark,
                isDestructive: true,
                onTap: () => ref.read(authNotifierProvider.notifier).logout(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, User user, bool isDark) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Bom dia';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 18) {
      greeting = 'Boa tarde';
      greetingIcon = Icons.wb_cloudy_rounded;
    } else {
      greeting = 'Boa noite';
      greetingIcon = Icons.nightlight_round;
    }
    
    final firstName = user.name.isNotEmpty 
        ? user.name.split(' ').first 
        : user.email.split('@').first;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.amber.withValues(alpha: 0.15) 
                : Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            greetingIcon,
            color: Colors.amber.shade700,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            Text(
              firstName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói a logo do cliente com suporte a dark mode
  Widget _buildLogo(BuildContext context, bool isDark) {
    final config = ClientConfig.current;
    
    Widget logo = Image.asset(
      config.logoPath,
      height: 36,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback para texto caso a imagem não carregue
        return Text(
          config.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(config.primaryColorHex),
          ),
        );
      },
    );

    if (isDark) {
      // Converte para escala de cinza e inverte para ficar branco
      logo = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: logo,
      );
      logo = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: logo,
      );
    }

    return logo;
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.isDark,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.08) 
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDestructive 
                ? Colors.red.shade400
                : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}

class _ModernMenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ModernMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_ModernMenuCard> createState() => _ModernMenuCardState();
}

class _ModernMenuCardState extends State<_ModernMenuCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.gradientColors.first.withValues(alpha: _isPressed ? 0.3 : 0.15),
              blurRadius: _isPressed ? 20 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decoração de fundo
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradientColors.map((c) => c.withValues(alpha: 0.1)).toList(),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Conteúdo
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Ícone com gradiente
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: widget.gradientColors.first.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Textos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Seta
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.gradientColors.first.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: widget.gradientColors.first,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}