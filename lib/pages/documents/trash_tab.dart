import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_desktop_uploader/controllers/document_controller.dart';
import 'package:my_desktop_uploader/models/models.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';
import 'package:my_desktop_uploader/widgets/document/file_type_icon.dart';
import 'package:intl/intl.dart';

class TrashTab extends StatelessWidget {
  const TrashTab({super.key});

  @override
  Widget build(BuildContext context) {
    final docCtrl = Get.find<DocumentController>();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Deleted Files pending permanent deletion',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Obx(() => IconButton(
                    tooltip: 'Refresh',
                    icon: docCtrl.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.primary))
                        : const Icon(Icons.refresh_rounded,
                            color: AppTheme.textSecondary),
                    onPressed: () => docCtrl.loadDocuments(refresh: true),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              final items = docCtrl.trashDocuments;

              if (docCtrl.isLoading && items.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (items.isEmpty) {
                return const _EmptyTrash();
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _TrashCard(document: items[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TrashCard extends StatefulWidget {
  final DocumentModel document;
  const _TrashCard({required this.document});

  @override
  State<_TrashCard> createState() => _TrashCardState();
}

class _TrashCardState extends State<_TrashCard> {
  bool _hovering = false;

  String _getRemainingTime(DateTime? deletedAt) {
    if (deletedAt == null) return '30d remaining';
    final expiry = deletedAt.add(const Duration(days: 30));
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) return 'Pending purge';
    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours % 24}h remaining';
    }
    return '${diff.inHours}h ${diff.inMinutes % 60}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final docCtrl = Get.find<DocumentController>();
    final deletedStr = doc.deletedAt != null 
        ? DateFormat('MMM dd, yyyy · HH:mm').format(doc.deletedAt!)
        : doc.dated.string;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _hovering ? AppTheme.surface : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovering
                ? AppTheme.error.withOpacity(0.5)
                : AppTheme.divider,
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: AppTheme.error.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FileTypeIcon(
                    extension: doc.type.extension,
                    mime: doc.type.mime,
                    size: 40,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'DELETED',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                doc.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Deleted: $deletedStr',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                'Owner: ${doc.ownerUsername}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.background.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getRemainingTime(doc.deletedAt),
                  style: TextStyle(
                    color: AppTheme.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => docCtrl.restoreDocument(doc.id),
                      icon: const Icon(Icons.settings_backup_restore_rounded, size: 14),
                      label: const Text('Restore', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.success,
                        side: BorderSide(color: AppTheme.success.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmPermanentDelete(context, doc, docCtrl),
                      icon: const Icon(Icons.delete_forever_rounded, size: 14),
                      label: const Text('Purge', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, DocumentModel doc, DocumentController ctrl) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Permanently Purge Document?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to permanently delete "${doc.name}"? This file will be purged from storage and cannot be retrieved by admins.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.forceDeleteDocument(doc.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Purge File'),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrash extends StatelessWidget {
  const _EmptyTrash();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                size: 40, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Trash is empty',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Deleted files will stay here for 30 days before purging',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
