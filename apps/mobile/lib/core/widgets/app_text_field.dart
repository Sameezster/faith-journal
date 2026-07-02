import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// A rounded, white text field with a leading icon — the standard input used
/// across the auth screens (Sign Up, Login, Forgot Password).
///
/// Most styling comes from the app's [InputDecorationTheme]; this widget just
/// wires up the icons, obscuring and a password visibility toggle.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.obscure = false,
    this.onToggleObscure,
    this.textInputAction,
  });

  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  /// When true the text is hidden (password fields).
  final bool obscure;

  /// If provided, a trailing eye icon is shown that calls this to toggle
  /// visibility. Pass the current [obscure] in so the right icon renders.
  final VoidCallback? onToggleObscure;

  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.warmGray),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure ? AppIcons.eye : AppIcons.eyeOff,
                  size: 20,
                  color: AppColors.warmGray,
                ),
              ),
      ),
    );
  }
}
