import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/client_config.dart';
import '../../../shared/providers/app_info_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/theme_selector.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final obscurePassword = useState(true);
    final rememberMe = useState(false);

    // FocusNodes para controle de foco
    final matriculaFocusNode = useFocusNode();
    final senhaFocusNode = useFocusNode();

    // Dar foco automático na matrícula ao iniciar (sem abrir teclado)
    useEffect(() {
      Future.microtask(() {
        matriculaFocusNode.requestFocus();
        // Esconde o teclado virtual caso abra
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      });
      return null;
    }, const []);

    final authState = ref.watch(authNotifierProvider);
    final config = ClientConfig.current;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Header com logo e seletor de tema
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo do cliente
                    _buildLogo(context, config),
                    const ThemeSelector(),
                  ],
                ),

                const SizedBox(height: 20),

                // Título
                Text(
                  'Entrar na sua conta',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 4),

                Text(
                  'Digite sua matrícula ou e-mail para entrar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 20),

                // Campo Email/Matrícula
                TextFormField(
                  controller: emailController,
                  focusNode: matriculaFocusNode,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula ou E-mail',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onFieldSubmitted: (_) {
                    senhaFocusNode.requestFocus();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite sua matrícula ou e-mail';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo Senha
                TextFormField(
                  controller: passwordController,
                  focusNode: senhaFocusNode,
                  obscureText: obscurePassword.value,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          obscurePassword.value = !obscurePassword.value,
                    ),
                  ),
                  onFieldSubmitted: (_) {
                    // Ao pressionar Enter na senha, faz login
                    if (formKey.currentState?.validate() ?? false) {
                      ref
                          .read(authNotifierProvider.notifier)
                          .login(
                            emailController.text.trim(),
                            passwordController.text,
                          );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite sua senha';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Lembrar-me
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: rememberMe.value,
                        onChanged: (value) => rememberMe.value = value ?? false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Lembrar-me', style: TextStyle(fontSize: 13)),
                  ],
                ),

                const SizedBox(height: 16),

                // Botão Entrar
                FilledButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            await ref
                                .read(authNotifierProvider.notifier)
                                .login(
                                  emailController.text.trim(),
                                  passwordController.text,
                                );
                          }
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                // Mostrar erro se houver
                if (authState.hasError) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authState.error.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Versão do app
                Center(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final versionAsync = ref.watch(appVersionProvider);
                      return Text(
                        'v${versionAsync.valueOrNull ?? "..."}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói a logo do cliente com suporte a dark mode
  Widget _buildLogo(BuildContext context, ClientConfig config) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget logo = Image.asset(
      config.logoPath,
      height: 60,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback para texto caso a imagem não carregue
        return Text(
          config.name,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(config.primaryColorHex),
          ),
        );
      },
    );

    if (isDark) {
      // Primeiro converte para escala de cinza
      logo = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: logo,
      );
      // Depois inverte (preto vira branco)
      logo = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: logo,
      );
    }

    return logo;
  }
}
