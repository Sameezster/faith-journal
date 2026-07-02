import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_widgets.dart';
import '../../../../core/widgets/sparkle_divider.dart';
import '../providers/auth_providers.dart';
import 'auth_errors.dart';

/// Login screen — sign in to an existing account.
///
/// Soft glow + leaves background, logo in the glow, "Welcome Back" title,
/// email + password fields, a Forgot password link, a gold Login button,
/// social sign-in options and a Sign Up link.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            _email.text.trim(),
            _password.text,
          );
      // Router redirect handles navigation on success.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _signInWithApple() {
    // Apple Sign-In requires Apple Developer setup — not wired up yet.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Apple Sign-In isn't available yet.")),
    );
  }

  void _goToSignUp() {
    context.pushReplacement('/register');
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // Logo.
                  Center(child: Image.asset(AppAssets.logo, width: 130)),
                  const SizedBox(height: 24),

                  // Title.
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.appTitle.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: SparkleDivider(lineWidth: 44, sparkleSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign in to continue your journey of faith.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.warmGray),
                  ),
                  const SizedBox(height: 36),

                  // Fields.
                  AppTextField(
                    hint: 'Email',
                    icon: AppIcons.mail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    hint: 'Password',
                    icon: AppIcons.lock,
                    controller: _password,
                    obscure: _obscure,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                  ),
                  const SizedBox(height: 12),

                  // Forgot password.
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => context.push('/reset-password'),
                      child: Text(
                        'Forgot password?',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Primary action.
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _signIn,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // "or continue with" divider.
                  const OrDivider(),
                  const SizedBox(height: 20),

                  // Social buttons.
                  Row(
                    children: [
                      Expanded(
                        child: SocialButton(
                          logo: AppAssets.googleLogo,
                          label: 'Google',
                          onTap: _signInWithGoogle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SocialButton(
                          logo: AppAssets.appleLogo,
                          label: 'Apple',
                          onTap: _signInWithApple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Sign Up link.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.warmGray),
                      ),
                      GestureDetector(
                        onTap: _goToSignUp,
                        child: Text(
                          'Sign Up',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
