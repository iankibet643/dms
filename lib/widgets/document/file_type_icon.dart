import 'package:flutter/material.dart';
import 'package:my_desktop_uploader/theme/app_theme.dart';

/// Renders a colored icon box based on file extension or MIME type.
class FileTypeIcon extends StatelessWidget {
  final String extension;
  final String mime;
  final double size;

  const FileTypeIcon({
    super.key,
    required this.extension,
    required this.mime,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolve(extension.toLowerCase(), mime);
    final iconSize = size * 0.52;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }

  static (IconData, Color) _resolve(String ext, String mime) {
    switch (ext) {
      case 'pdf':
        return (Icons.picture_as_pdf_rounded, AppTheme.pdfColor);
      case 'doc':
      case 'docx':
        return (Icons.description_rounded, AppTheme.docColor);
      case 'xls':
      case 'xlsx':
      case 'csv':
        return (Icons.table_chart_rounded, AppTheme.xlsColor);
      case 'ppt':
      case 'pptx':
        return (Icons.slideshow_rounded, AppTheme.pptColor);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'svg':
        return (Icons.image_rounded, AppTheme.imgColor);
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return (Icons.video_file_rounded, AppTheme.videoColor);
      case 'mp3':
      case 'wav':
      case 'ogg':
        return (Icons.audio_file_rounded, AppTheme.videoColor);
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return (Icons.folder_zip_rounded, AppTheme.archiveColor);
      case 'txt':
      case 'md':
        return (Icons.text_snippet_rounded, AppTheme.docColor);
      default:
        // Fallback to MIME prefix
        if (mime.startsWith('image/')) {
          return (Icons.image_rounded, AppTheme.imgColor);
        }
        if (mime.startsWith('video/')) {
          return (Icons.video_file_rounded, AppTheme.videoColor);
        }
        if (mime.startsWith('audio/')) {
          return (Icons.audio_file_rounded, AppTheme.videoColor);
        }
        if (mime.contains('pdf')) {
          return (Icons.picture_as_pdf_rounded, AppTheme.pdfColor);
        }
        return (Icons.insert_drive_file_rounded, AppTheme.defaultFileColor);
    }
  }
}
