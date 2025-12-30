import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final obscurePassword = useState(true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Logo/Icon
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.blue,
                )
                    .animate()
                    .scale(duration: AppConstants.mediumAnimation)
                    .then()
                    .shimmer(duration: 2.seconds),
                
                const SizedBox(height: 32),
                
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(duration: AppConstants.mediumAnimation, delay: 200.ms),
                
                const SizedBox(height: 8),
                
                Text(
                  'Sign in to continue to ${AppConstants.appName}',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(duration: AppConstants.mediumAnimation, delay: 300.ms),
                
                const SizedBox(height: 48),
                
                // Email Field
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                )
                    .animate()
                    .slideX(
                      duration: AppConstants.mediumAnimation, 
                      delay: 400.ms,
                      begin: -0.3,
                    ),
                
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword.value,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => obscurePassword.value = !obscurePassword.value,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < AppConstants.minPasswordLength) {
                      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                    }
                    return null;
                  },
                )
                    .animate()
                    .slideX(
                      duration: AppConstants.mediumAnimation, 
                      delay: 500.ms,
                      begin: 0.3,
                    ),
                
                const SizedBox(height: 24),
                
                // Login Button
                FilledButton(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            isLoading.value = true;
                            
                            // Simulate API call
                            await Future.delayed(const Duration(seconds: 2));
                            
                            isLoading.value = false;
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Login successful! (Demo)'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              context.go(AppConstants.homeRoute);
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                )
                    .animate()
                    .scale(
                      duration: AppConstants.mediumAnimation, 
                      delay: 600.ms,
                    ),
                
                const SizedBox(height: 16),
                
                // Register Link
                TextButton(
                  onPressed: () => context.push(AppConstants.registerRoute),
                  child: const Text("Don't have an account? Sign up"),
                )
                    .animate()
                    .fadeIn(duration: AppConstants.mediumAnimation, delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}