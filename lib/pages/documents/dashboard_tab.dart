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
          Obx(() => Row(
                children: [
                  _StatCard(
                    icon: Icons.folder_rounded,
                    iconColor: AppTheme.primary,
                    label: 'Total Documents',
                    value: doc.totalDocuments.toString(),
                    subtitle: 'Files in your vault',
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
                    subtitle: 'Only visible to you',
                  ),
                ],
              )),

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
        ],
      ),
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
