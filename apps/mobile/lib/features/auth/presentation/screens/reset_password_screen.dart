import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';

/// Screen 8 — Reset Password: email -> Send Reset Link (Firebase sendPasswordResetEmail).
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FjSpacing.xxl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 24),
            Text('Reset Password',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 6),
            const Text("Enter your email and we'll send you a reset link",
                textAlign: TextAlign.center, style: TextStyle(color: FjColors.gray500)),
            const SizedBox(height: FjSpacing.xxl),
            const TextField(decoration: InputDecoration(hintText: 'Email')),
            const SizedBox(height: FjSpacing.lg),
            ElevatedButton(onPressed: () {}, child: const Text('Send Reset Link')),
          ]),
        ),
      ),
    );
  }
}
