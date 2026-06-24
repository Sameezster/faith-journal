import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/tokens.dart';

/// Screen 6 — Create Account: name/email/password + Google/Apple. (TODO: controller wiring.)
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FjSpacing.xxl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Create Account',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 6),
            const Text('Begin your journey of faith and reflection.',
                textAlign: TextAlign.center, style: TextStyle(color: FjColors.gray500)),
            const SizedBox(height: FjSpacing.xxl),
            const TextField(decoration: InputDecoration(hintText: 'Full name')),
            const SizedBox(height: FjSpacing.md),
            const TextField(decoration: InputDecoration(hintText: 'Email')),
            const SizedBox(height: FjSpacing.md),
            const TextField(obscureText: true, decoration: InputDecoration(hintText: 'Password')),
            const SizedBox(height: FjSpacing.lg),
            ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Sign Up')),
          ]),
        ),
      ),
    );
  }
}
