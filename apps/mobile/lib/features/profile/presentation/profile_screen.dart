import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final profile = ref.watch(userProfileProvider).value;

    final displayName =
        profile?.displayName ?? authUser?.displayName ?? 'Faith Journal user';
    final email = profile?.email ?? authUser?.email ?? '';
    final photoUrl = profile?.photoUrl ?? authUser?.photoUrl;
    final translation = profile?.preferredTranslation ?? 'KJV';

    return Scaffold(
      backgroundColor: FjColors.cream50,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            FjSpacing.gutter,
            FjSpacing.lg,
            FjSpacing.gutter,
            FjSpacing.xxxl,
          ),
          children: [
            Text(
              'Profile & Settings',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: FjSpacing.lg),
            _UserCard(
              displayName: displayName,
              email: email,
              photoUrl: photoUrl,
              onEdit: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile editing — coming soon.')),
              ),
            ),
            const SizedBox(height: FjSpacing.lg),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.menu_book_outlined,
                  iconColor: FjColors.sage500,
                  title: 'Bible Version',
                  subtitle: _bibleVersionLabel(translation),
                  onTap: () => context.go('/saved-verses'),
                ),
                const _Separator(),
                _SettingsRow(
                  icon: Icons.notifications_outlined,
                  iconColor: FjColors.sage500,
                  title: 'Notifications',
                  subtitle: 'Manage your reminders',
                  onTap: () => context.go('/reminders'),
                ),
                const _Separator(),
                _SettingsRow(
                  icon: Icons.wb_sunny_outlined,
                  iconColor: FjColors.gold500,
                  title: 'Theme',
                  subtitle: 'Light',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dark mode — coming soon.')),
                  ),
                ),
                const _Separator(),
                _SettingsRow(
                  icon: Icons.shield_outlined,
                  iconColor: FjColors.sage500,
                  title: 'Privacy',
                  subtitle: 'Manage your data & privacy',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Privacy settings — coming soon.')),
                  ),
                ),
                const _Separator(),
                _SettingsRow(
                  icon: Icons.help_outline,
                  iconColor: FjColors.sage500,
                  title: 'Help',
                  subtitle: 'FAQ & Support',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help center — coming soon.')),
                  ),
                ),
                const _Separator(),
                _SettingsRow(
                  icon: Icons.info_outline,
                  iconColor: FjColors.sage500,
                  title: 'About',
                  subtitle: 'Faith Journal v1.0.0',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Faith Journal',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 SelinyxTech. Built with care.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: FjSpacing.lg),
            _LogOutButton(onTap: () => _confirmSignOut(context, ref)),
          ],
        ),
      ),
    );
  }

  static String _bibleVersionLabel(String code) => switch (code) {
        'KJV' => 'KJV (King James Version)',
        'WEB' => 'WEB (World English Bible)',
        'ESV' => 'ESV (English Standard Version)',
        'NIV' => 'NIV (New International Version)',
        _ => code,
      };

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.onEdit,
  });

  final String displayName;
  final String email;
  final String? photoUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FjSpacing.lg),
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        boxShadow: [
          BoxShadow(
            color: FjColors.navy900.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: FjColors.gold500, width: 2),
            ),
            child: ClipOval(
              child: photoUrl != null
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: FjColors.gold300,
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 36),
                      ),
                    )
                  : Container(
                      color: FjColors.gold300,
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 36),
                    ),
            ),
          ),
          const SizedBox(width: FjSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: FjColors.navy900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: FjColors.gray500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: FjSpacing.sm),
          Material(
            color: FjColors.gold500.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child:
                    const Icon(Icons.edit, color: FjColors.gold500, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        boxShadow: [
          BoxShadow(
            color: FjColors.navy900.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FjSpacing.lg,
          vertical: FjSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: FjSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: FjColors.navy900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: FjColors.gray500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FjColors.gold500),
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FjSpacing.lg),
      child: Container(height: 1, color: FjColors.gray300),
    );
  }
}

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FjColors.surface0,
      borderRadius: BorderRadius.circular(FjRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(FjRadius.card),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FjRadius.card),
            boxShadow: [
              BoxShadow(
                color: FjColors.navy900.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: FjSpacing.lg,
            vertical: FjSpacing.md,
          ),
          child: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFB91C1C)),
              SizedBox(width: FjSpacing.md),
              Expanded(
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Color(0xFFB91C1C)),
            ],
          ),
        ),
      ),
    );
  }
}
