import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_desktop_uploader/controllers/auth_controller.dart';
import 'package:my_desktop_uploader/controllers/document_controller.dart';
import 'package:my_desktop_uploader/pages/documents/dashboard_tab.dart';
import 'package:my_desktop_uploader/pages/documents/documents_tab.dart';
import 'package:my_desktop_uploader/pages/documents/restored_tab.dart';
import 'package:my_desktop_uploader/pages/documents/trash_tab.dart';
import 'package:my_desktop_uploader/pages/documents/upload_tab.dart';
import 'package:my_desktop_uploader/pages/profile/profile_tab.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';
import 'package:my_desktop_uploader/widgets/common/sidebar.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _selectedIndex = 0;

  final _pages = const [
    DashboardTab(),
    DocumentsTab(),
    RestoredTab(),
    TrashTab(),
    UploadTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Sidebar
          SidebarWidget(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                _TopBar(pageIndex: _selectedIndex),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int pageIndex;
  const _TopBar({required this.pageIndex});

  static const _titles = [
    'Dashboard',
    'Documents',
    'Restored Files',
    'Trash Bin',
    'Upload Files',
    'Profile'
  ];
  static const _subtitles = [
    'Overview of your document vault',
    'Browse and manage your files',
    'Directory of recovered documents',
    'Soft-deleted items pending purging',
    'Upload new files to your vault',
    'Account settings and info',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          // Page title
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titles[pageIndex],
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _subtitles[pageIndex],
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Search bar
          if (pageIndex == 1 || pageIndex == 2 || pageIndex == 3) const _SearchBar(),
          const SizedBox(width: 20),
          // User avatar
          Obx(() => _UserAvatarButton(
                name: auth.displayName,
                avatarUrl: auth.avatar,
              )),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final docCtrl = Get.find<DocumentController>();
    return SizedBox(
      width: 280,
      height: 40,
      child: TextField(
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search documents…',
          hintStyle:
              const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (q) {
          if (q.length > 2 || q.isEmpty) {
            docCtrl.setSearch(q);
          }
        },
      ),
    );
  }
}

class _UserAvatarButton extends StatelessWidget {
  final String name;
  final String avatarUrl;

  const _UserAvatarButton({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return GestureDetector(
      onTapDown: (details) {
        showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx - 160,
            details.globalPosition.dy + 10,
            details.globalPosition.dx,
            details.globalPosition.dy + 200,
          ),
          color: AppTheme.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          items: <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    auth.user?.email ?? '',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              onTap: auth.logout,
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded,
                      size: 18, color: AppTheme.textSecondary),
                  SizedBox(width: 12),
                  Text('Sign Out',
                      style: TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ],
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.split(' ').first,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() => Text(
                auth.user?.isSuperAdmin ?? false
                    ? 'Super Admin'
                    : auth.user?.isAdmin ?? false
                        ? 'Admin'
                        : 'User',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              )),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textSecondary, size: 18),
        ],
      ),
    );
  }
}
