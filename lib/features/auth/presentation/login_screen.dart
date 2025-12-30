import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
    
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Header com logo e seletor de tema
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WinConnect',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const ThemeSelector(),
                  ],
                ),
                
                const SizedBox(height: 60),
                
                // Título
                Text(
                  'Entrar na sua conta',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Digite seu e-mail e senha abaixo para entrar',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Campo Email
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite seu e-mail';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor, digite um e-mail válido';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Campo Senha
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword.value,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => obscurePassword.value = !obscurePassword.value,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite sua senha';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Lembrar-me
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe.value,
                      onChanged: (value) => rememberMe.value = value ?? false,
                    ),
                    const Text('Lembrar-me'),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Botão Entrar
                FilledButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            await ref.read(authNotifierProvider.notifier).login(
                              emailController.text.trim(),
                              passwordController.text,
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                
                // Mostrar erro se houver
                if (authState.hasError) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authState.error.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}