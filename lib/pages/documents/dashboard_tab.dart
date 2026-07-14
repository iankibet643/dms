import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_desktop_uploader/controllers/auth_controller.dart';
import 'package:my_desktop_uploader/controllers/document_controller.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';
import 'package:my_desktop_uploader/widgets/document/document_card.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final doc = Get.find<DocumentController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Obx(() => _WelcomeBanner(name: auth.displayName)),
          const SizedBox(height: 28),

          // Stats row
          Obx(() {
            final isAdmin = auth.user?.isAdmin ?? false;
            return Row(
              children: [
                _StatCard(
                  icon: Icons.folder_rounded,
                  iconColor: AppTheme.primary,
                  label: 'Total Documents',
                  value: doc.totalDocuments.toString(),
                  subtitle: 'Active files in vault',
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.storage_rounded,
                  iconColor: AppTheme.accent,
                  label: 'Storage Used',
                  value: doc.storageUsedFormatted,
                  subtitle: 'Across all files',
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.public_rounded,
                  iconColor: AppTheme.success,
                  label: 'Public Files',
                  value: doc.documents
                      .where((d) => d.visibility.isPublic)
                      .length
                      .toString(),
                  subtitle: 'Shared with others',
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.lock_rounded,
                  iconColor: AppTheme.warning,
                  label: 'Private Files',
                  value: doc.documents
                      .where((d) => !d.visibility.isPublic)
                      .length
                      .toString(),
                  subtitle: 'Visible to owners',
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 16),
                  _StatCard(
                    icon: Icons.delete_sweep_rounded,
                    iconColor: AppTheme.error,
                    label: 'Trash Items',
                    value: doc.trashDocuments.length.toString(),
                    subtitle: 'Recoverable files',
                  ),
                ],
              ],
            );
          }),

          const SizedBox(height: 32),

          // Recent Documents
          const Text(
            'Recent Documents',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your most recently uploaded files',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          Obx(() {
            if (doc.isLoading && doc.documents.isEmpty) {
              return const _LoadingGrid();
            }
            if (doc.documents.isEmpty) {
              return const _EmptyState();
            }
            final recent = doc.documents.take(6).toList();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: recent.length,
              itemBuilder: (_, i) => DocumentCard(document: recent[i]),
            );
          }),

          // Admin Activity Log Feed
          Obx(() {
            final isAdmin = auth.user?.isAdmin ?? false;
            if (!isAdmin) return const SizedBox();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 36),
                const _AdminActivityFeed(),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Admin Activity Feed Widget ───────────────────────────────────────────────

class _AdminActivityFeed extends StatelessWidget {
  const _AdminActivityFeed();

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative) return 'Just now';
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final docCtrl = Get.find<DocumentController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Activity Log (Admin View)',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Monitor newly uploaded and updated documents across the system',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final logs = docCtrl.recentActivities;
          if (logs.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Center(
                child: Text(
                  'No recent system activities recorded.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length > 5 ? 5 : logs.length, // Show up to 5 items
              separatorBuilder: (_, __) => Divider(color: AppTheme.divider, height: 1),
              itemBuilder: (_, i) {
                final log = logs[i];
                IconData icon;
                Color color;
                String badgeText;
                
                switch (log.type) {
                  case 'new':
                    icon = Icons.cloud_upload_rounded;
                    color = AppTheme.success;
                    badgeText = 'NEW';
                    break;
                  case 'update':
                    icon = Icons.edit_note_rounded;
                    color = AppTheme.accent;
                    badgeText = 'UPDATED';
                    break;
                  case 'restore':
                    icon = Icons.restore_rounded;
                    color = AppTheme.primary;
                    badgeText = 'RESTORED';
                    break;
                  case 'delete':
                    icon = Icons.delete_sweep_rounded;
                    color = AppTheme.error;
                    badgeText = 'DELETED';
                    break;
                  default:
                    icon = Icons.info_rounded;
                    color = AppTheme.textSecondary;
                    badgeText = 'INFO';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _timeAgo(log.timestamp),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                                children: [
                                  TextSpan(
                                    text: log.fileName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const TextSpan(text: ' was '),
                                  TextSpan(
                                    text: log.type == 'new' 
                                        ? 'uploaded' 
                                        : log.type == 'update'
                                            ? 'updated'
                                            : log.type == 'restore'
                                                ? 'restored'
                                                : 'soft-deleted',
                                    style: TextStyle(color: color, fontWeight: FontWeight.w500),
                                  ),
                                  const TextSpan(text: ' by '),
                                  TextSpan(
                                    text: log.ownerUsername,
                                    style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;
  const _WelcomeBanner({required this.name});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryDark,
            AppTheme.primary.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, ${name.split(' ').first}! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your documents are safe and organized. Ready to get started?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.folder_special_rounded,
                color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Icon(Icons.trending_up_rounded,
                    color: AppTheme.success, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded,
                size: 80, color: AppTheme.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'No documents yet',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload your first document to get started',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
