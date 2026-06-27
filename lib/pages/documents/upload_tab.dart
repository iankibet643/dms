import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_desktop_uploader/controllers/document_controller.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';

class UploadTab extends StatelessWidget {
  const UploadTab({super.key});

  @override
  Widget build(BuildContext context) {
    final doc = Get.find<DocumentController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drop zone
          Obx(() => _DropZone(
                onPick: doc.pickFiles,
                isUploading: doc.isUploading,
              )),
          const SizedBox(height: 24),

          // Selected files
          Obx(() {
            if (doc.selectedFiles.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Selected Files',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${doc.selectedFiles.length}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: doc.clearSelectedFiles,
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: doc.selectedFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final file = doc.selectedFiles[i];
                    final sizeStr = file.size > 0
                        ? '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'
                        : 'Unknown size';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          _fileIcon(file.name),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sizeStr,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded,
                                color: AppTheme.error, size: 20),
                            onPressed: () => doc.removeSelectedFile(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Progress
                Obx(() {
                  if (!doc.isUploading) return const SizedBox.shrink();
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Uploading…',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${(doc.uploadProgress * 100).toStringAsFixed(0)}%',
                            style:
                                const TextStyle(color: AppTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: doc.uploadProgress,
                          minHeight: 8,
                          backgroundColor: AppTheme.divider,
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }),

                // Upload button
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: doc.isUploading || doc.selectedFiles.isEmpty
                            ? null
                            : doc.uploadSelectedFiles,
                        icon: doc.isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload_rounded, size: 20),
                        label: Text(doc.isUploading
                            ? 'Uploading…'
                            : 'Upload ${doc.selectedFiles.length} File(s)'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    )),
              ],
            );
          }),

          const SizedBox(height: 32),

          // Upload results
          Obx(() {
            if (doc.uploadResults.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Results',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...doc.uploadResults.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: r.success
                              ? AppTheme.success.withOpacity(0.08)
                              : AppTheme.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: r.success
                                ? AppTheme.success.withOpacity(0.3)
                                : AppTheme.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              r.success
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              color:
                                  r.success ? AppTheme.success : AppTheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.fileName,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (r.document != null)
                                    Text(
                                      r.document!.size.string,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (!r.success && r.message != null)
                                    Text(
                                      r.message!,
                                      style: TextStyle(
                                        color: AppTheme.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (r.success)
                              Chip(
                                label: const Text('Uploaded',
                                    style: TextStyle(
                                        color: AppTheme.success,
                                        fontSize: 12)),
                                backgroundColor:
                                    AppTheme.success.withOpacity(0.1),
                                side:
                                    BorderSide(color: AppTheme.success.withOpacity(0.3)),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ),
                    )),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    Color color;
    IconData icon;
    switch (ext) {
      case 'pdf':
        color = AppTheme.pdfColor;
        icon = Icons.picture_as_pdf_rounded;
        break;
      case 'doc':
      case 'docx':
        color = AppTheme.docColor;
        icon = Icons.description_rounded;
        break;
      case 'xls':
      case 'xlsx':
        color = AppTheme.xlsColor;
        icon = Icons.table_chart_rounded;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        color = AppTheme.imgColor;
        icon = Icons.image_rounded;
        break;
      default:
        color = AppTheme.defaultFileColor;
        icon = Icons.insert_drive_file_rounded;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

// ── Drop Zone ────────────────────────────────────────────────────────────────

class _DropZone extends StatefulWidget {
  final VoidCallback onPick;
  final bool isUploading;
  const _DropZone({required this.onPick, required this.isUploading});

  @override
  State<_DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.isUploading ? null : widget.onPick,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
          decoration: BoxDecoration(
            color: _hovering
                ? AppTheme.primary.withOpacity(0.06)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovering ? AppTheme.primary : AppTheme.divider,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: (_hovering ? AppTheme.primary : AppTheme.primary)
                      .withOpacity(_hovering ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  size: 36,
                  color: _hovering ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _hovering
                    ? 'Click to browse files'
                    : 'Click to Select Files',
                style: TextStyle(
                  color: _hovering ? AppTheme.primary : AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'PDF, DOCX, XLSX, Images, and more',
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Maximum file size: 50 MB',
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
