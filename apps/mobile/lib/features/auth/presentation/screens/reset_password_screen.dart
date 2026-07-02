import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/sparkle_divider.dart';
import '../providers/auth_providers.dart';
import 'auth_errors.dart';

/// Reset Password screen — request a password reset link by email.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_busy) return;
    final email = _email.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email address.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your inbox for the reset link.')),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.backgroundSoft, fit: BoxFit.cover),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back arrow.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(AppIcons.backArrow, color: AppColors.navy),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Logo.
                  Center(child: Image.asset(AppAssets.logo, width: 170)),
                  const SizedBox(height: 28),

                  // Title.
                  Text(
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.appTitle.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: SparkleDivider(lineWidth: 44, sparkleSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Enter your email and we'll send you a reset link",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.warmGray),
                  ),
                  const SizedBox(height: 40),

                  // Email field.
                  AppTextField(
                    hint: 'Email',
                    icon: AppIcons.mail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),

                  // Primary action.
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _sendResetLink,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send Reset Link'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
