import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_desktop_uploader/controllers/document_controller.dart';
import 'package:my_desktop_uploader/models/models.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';
import 'package:my_desktop_uploader/widgets/document/file_type_icon.dart';
import 'package:url_launcher/url_launcher.dart';

class RestoredTab extends StatelessWidget {
  const RestoredTab({super.key});

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
                'Recovered files restored to separate folder',
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
              final items = docCtrl.restoredDocuments;

              if (docCtrl.isLoading && items.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (items.isEmpty) {
                return const _EmptyRestored();
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.76,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _RestoredCard(document: items[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RestoredCard extends StatefulWidget {
  final DocumentModel document;
  const _RestoredCard({required this.document});

  @override
  State<_RestoredCard> createState() => _RestoredCardState();
}

class _RestoredCardState extends State<_RestoredCard> {
  bool _hovering = false;

  void _openFile(DocumentModel doc) async {
    final url = doc.links.detail;
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

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
                ? AppTheme.success.withOpacity(0.5)
                : AppTheme.divider,
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: AppTheme.success.withOpacity(0.04),
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
                      color: AppTheme.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 10, color: AppTheme.success),
                        SizedBox(width: 4),
                        Text(
                          'RESTORED',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
              const SizedBox(height: 4),
              Text(
                'Owner: ${doc.ownerUsername}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              // Actions buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openFile(doc),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Open', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => docCtrl.deleteDocument(doc.id),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                    tooltip: 'Send to Trash',
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.error.withOpacity(0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}

class _VisibilityBadge extends StatelessWidget {
  final bool isPublic;
  const _VisibilityBadge({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: (isPublic ? AppTheme.success : AppTheme.warning).withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        isPublic ? Icons.public_rounded : Icons.lock_rounded,
        size: 9,
        color: isPublic ? AppTheme.success : AppTheme.warning,
      ),
    );
  }
}

class _EmptyRestored extends StatelessWidget {
  const _EmptyRestored();

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
            child: const Icon(Icons.restore_page_rounded,
                size: 40, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Restored Files',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Documents you recover from Trash will show up in this folder',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
