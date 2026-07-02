import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A centered "or continue with" label flanked by thin rules.
/// Shared by the Sign Up and Login screens.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'or continue with'});

  final String label;

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: Divider(color: AppColors.divider, thickness: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppColors.warmGray),
          ),
        ),
        line,
      ],
    );
  }
}

/// A white rounded button with a brand logo image and label
/// (Google / Apple social sign-in).
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.logo,
    required this.label,
    required this.onTap,
  });

  final String logo;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Image.asset(logo, width: 22, height: 22),
      label: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: AppColors.charcoal,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
