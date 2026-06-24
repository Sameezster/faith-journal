import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/tokens.dart';

/// Screen 7 — Welcome Back. Email/password + Google/Apple + forgot password.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FjSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text('Welcome Back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 6),
              const Text('Sign in to continue your journey of faith.',
                  textAlign: TextAlign.center, style: TextStyle(color: FjColors.gray500)),
              const SizedBox(height: FjSpacing.xxl),
              const TextField(decoration: InputDecoration(hintText: 'Email')),
              const SizedBox(height: FjSpacing.md),
              const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                      hintText: 'Password', suffixIcon: Icon(Icons.visibility_outlined))),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => context.go('/reset-password'),
                    child: const Text('Forgot password?',
                        style: TextStyle(color: FjColors.navy900))),
              ),
              ElevatedButton(
                  onPressed: () => context.go('/home'), // TODO: AuthController.signIn
                  child: const Text('Login')),
              const SizedBox(height: FjSpacing.lg),
              const Text('or continue with',
                  textAlign: TextAlign.center, style: TextStyle(color: FjColors.gray500)),
              const SizedBox(height: FjSpacing.md),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                    onPressed: () {}, icon: const Icon(Icons.g_mobiledata), label: const Text('Google'))),
                const SizedBox(width: FjSpacing.md),
                Expanded(child: OutlinedButton.icon(
                    onPressed: () {}, icon: const Icon(Icons.apple), label: const Text('Apple'))),
              ]),
              TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text("Don't have an account? Sign Up")),
            ],
          ),
        ),
      ),
    );
  }
}
