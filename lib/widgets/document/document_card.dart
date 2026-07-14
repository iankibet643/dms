import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_desktop_uploader/controllers/document_controller.dart';
import 'package:my_desktop_uploader/models/models.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';
import 'package:my_desktop_uploader/widgets/document/file_type_icon.dart';

class DocumentCard extends StatefulWidget {
  final DocumentModel document;
  const DocumentCard({super.key, required this.document});

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final docCtrl = Get.find<DocumentController>();

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
                ? AppTheme.primary.withOpacity(0.4)
                : AppTheme.divider,
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openDocument(doc),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File type icon + action menu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FileTypeIcon(
                        extension: doc.type.extension,
                        mime: doc.type.mime,
                        size: 44,
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (v) => _onMenuSelected(v, doc, docCtrl),
                        color: AppTheme.surfaceCard,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: Row(children: [
                              Icon(Icons.open_in_new_rounded,
                                  size: 16, color: AppTheme.textSecondary),
                              SizedBox(width: 10),
                              Text('Open',
                                  style: TextStyle(color: AppTheme.textPrimary)),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'copy_link',
                            child: Row(children: [
                              Icon(Icons.link_rounded,
                                  size: 16, color: AppTheme.textSecondary),
                              SizedBox(width: 10),
                              Text('Copy Link',
                                  style: TextStyle(color: AppTheme.textPrimary)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: doc.visibility.isPublic ? 'make_private' : 'make_public',
                            child: Row(children: [
                              Icon(
                                doc.visibility.isPublic ? Icons.lock_outline_rounded : Icons.public_rounded,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                doc.visibility.isPublic ? 'Make Private' : 'Make Public',
                                style: const TextStyle(color: AppTheme.textPrimary),
                              ),
                            ]),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 16, color: AppTheme.error),
                              const SizedBox(width: 10),
                              Text('Delete',
                                  style: TextStyle(color: AppTheme.error)),
                            ]),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: _hovering
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // File name
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
                  const SizedBox(height: 8),
                  // Meta row
                  Row(
                    children: [
                      Text(
                        doc.size.string,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      _VisibilityBadge(isPublic: doc.visibility.isPublic),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doc.dated.string,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
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

  void _onMenuSelected(
      String value, DocumentModel doc, DocumentController ctrl) async {
    switch (value) {
      case 'open':
        _openDocument(doc);
        break;
      case 'copy_link':
        Get.snackbar('Copied', 'Link copied to clipboard',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2));
        break;
      case 'make_public':
        ctrl.updateDocumentVisibility(doc.id, 'pub');
        break;
      case 'make_private':
        ctrl.updateDocumentVisibility(doc.id, 'pri');
        break;
      case 'delete':
        _confirmDelete(doc, ctrl);
        break;
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
          'Are you sure you want to delete "${doc.name}"? It will be moved to the Trash Bin for safety and can be retrieved by an administrator.',
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (isPublic ? AppTheme.success : AppTheme.warning)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_rounded,
            size: 10,
            color: isPublic ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(
              color: isPublic ? AppTheme.success : AppTheme.warning,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
