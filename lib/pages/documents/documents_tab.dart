import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_desktop_uploader/controllers/document_controller.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';
import 'package:my_desktop_uploader/widgets/document/document_card.dart';
import 'package:my_desktop_uploader/widgets/document/document_list_tile.dart';

class DocumentsTab extends StatelessWidget {
  const DocumentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final doc = Get.find<DocumentController>();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter + View Toggle row
          Row(
            children: [
              // Visibility filter chips
              Obx(() => Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: doc.filterVisibility == '',
                        onTap: () => doc.setFilterVisibility(''),
                      ),
                      _FilterChip(
                        label: '🔒 Private',
                        selected: doc.filterVisibility == 'pri',
                        onTap: () => doc.setFilterVisibility('pri'),
                      ),
                      _FilterChip(
                        label: '🌐 Public',
                        selected: doc.filterVisibility == 'pub',
                        onTap: () => doc.setFilterVisibility('pub'),
                      ),
                    ],
                  )),
              const Spacer(),
              // Refresh button
              Obx(() => IconButton(
                    tooltip: 'Refresh',
                    icon: doc.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.primary))
                        : const Icon(Icons.refresh_rounded,
                            color: AppTheme.textSecondary),
                    onPressed: () => doc.loadDocuments(refresh: true),
                  )),
              // Grid/List toggle
              Obx(() => IconButton(
                    tooltip: doc.viewMode == 'grid'
                        ? 'Switch to list'
                        : 'Switch to grid',
                    icon: Icon(
                      doc.viewMode == 'grid'
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: doc.toggleViewMode,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          // Document grid/list
          Expanded(
            child: Obx(() {
              final items = doc.filteredDocuments;

              if (doc.isLoading && items.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (items.isEmpty) {
                return _EmptyDocuments(onUpload: () {});
              }

              if (doc.viewMode == 'grid') {
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => DocumentCard(document: items[i]),
                );
              } else {
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      DocumentListTile(document: items[i]),
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyDocuments({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Icon(Icons.folder_open_rounded,
                size: 50, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          const Text(
            'No documents found',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload your first document to get started',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
            label: const Text('Upload Document'),
          ),
        ],
      ),
    );
  }
}
