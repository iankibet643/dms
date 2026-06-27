import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_desktop_uploader/controllers/document_controller.dart';
import 'package:my_desktop_uploader/models/models.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';
import 'package:my_desktop_uploader/widgets/document/file_type_icon.dart';

class DocumentListTile extends StatefulWidget {
  final DocumentModel document;
  const DocumentListTile({super.key, required this.document});

  @override
  State<DocumentListTile> createState() => _DocumentListTileState();
}

class _DocumentListTileState extends State<DocumentListTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final docCtrl = Get.find<DocumentController>();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovering ? AppTheme.surface : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovering
                ? AppTheme.primary.withOpacity(0.3)
                : AppTheme.divider,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openDocument(doc),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  FileTypeIcon(
                    extension: doc.type.extension,
                    mime: doc.type.mime,
                    size: 38,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              doc.type.extension.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const Text(' · ',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                            Text(
                              doc.size.string,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Date
                  SizedBox(
                    width: 130,
                    child: Text(
                      doc.dated.string,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Visibility badge
                  _VisibilityBadge(isPublic: doc.visibility.isPublic),
                  const SizedBox(width: 12),
                  // Actions
                  if (_hovering)
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Open',
                          icon: const Icon(Icons.open_in_new_rounded,
                              size: 18, color: AppTheme.primary),
                          onPressed: () => _openDocument(doc),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppTheme.error),
                          onPressed: () => _confirmDelete(doc, docCtrl),
                        ),
                      ],
                    )
                  else
                    const SizedBox(width: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDocument(DocumentModel doc) async {
    final url = doc.links.detail;
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _confirmDelete(DocumentModel doc, DocumentController ctrl) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Document?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Delete "${doc.name}"? This cannot be undone.',
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
              ctrl.deleteDocument(doc.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final bool isPublic;
  const _VisibilityBadge({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPublic ? AppTheme.success : AppTheme.warning)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_rounded,
            size: 11,
            color: isPublic ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(
              color: isPublic ? AppTheme.success : AppTheme.warning,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
