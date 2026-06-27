import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:my_desktop_uploader/controllers/auth_controller.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Obx(() {
        final user = auth.user;
        if (user == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primary,
                        backgroundImage: user.avatar.isNotEmpty
                            ? NetworkImage(user.avatar)
                            : null,
                        child: user.avatar.isEmpty
                            ? Text(
                                user.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppTheme.surfaceCard, width: 3),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _BadgeChip(Icons.email_outlined, user.email),
                            _BadgeChip(Icons.phone_outlined, user.phone),
                            _BadgeChip(
                                Icons.schedule_outlined, user.timezone),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    tooltip: 'Refresh profile',
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppTheme.textSecondary),
                    onPressed: auth.refreshProfile,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact info
                Expanded(
                  child: _InfoCard(
                    title: 'Contact Information',
                    icon: Icons.contact_page_outlined,
                    items: [
                      _InfoRow('Email', user.email, Icons.email_outlined),
                      _InfoRow('Phone', user.phone, Icons.phone_outlined),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Account info
                Expanded(
                  child: _InfoCard(
                    title: 'Account Details',
                    icon: Icons.manage_accounts_outlined,
                    items: [
                      _InfoRow('Username', user.username,
                          Icons.person_outline_rounded),
                      _InfoRow(
                          'Member Since',
                          user.joinDate.split(' ').first,
                          Icons.calendar_today_outlined),
                      _InfoRow('Timezone', user.timezone,
                          Icons.public_outlined),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Danger zone
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.error.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.error, size: 24),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danger Zone',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Signing out will clear your session and return you to the login screen.',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _showLogoutConfirm(),
                    icon: const Icon(Icons.logout_rounded,
                        size: 16, color: AppTheme.error),
                    label: const Text('Sign Out',
                        style: TextStyle(color: AppTheme.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showLogoutConfirm() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: Get.back,
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<AuthController>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BadgeChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> items;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppTheme.divider),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (value.isNotEmpty)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                Get.snackbar('Copied', '$label copied to clipboard',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2));
              },
              child: const Icon(Icons.copy_rounded,
                  size: 15, color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}
