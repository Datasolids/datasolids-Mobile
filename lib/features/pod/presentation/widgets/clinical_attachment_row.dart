// Shared attachment row — used by the DR/DocRef/ImagingStudy detail
// screens. Tap-to-open via url_launcher (presigned S3 URL).

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClinicalAttachmentRow extends StatelessWidget {
  const ClinicalAttachmentRow({super.key, required this.att});
  final ClinicalAttachment att;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (!att.isDownloadable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not available yet — try again shortly'),
            ),
          );
          return;
        }
        final uri = Uri.tryParse(att.fileUrl!);
        if (uri == null) return;
        final ok =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't open the file")),
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBg(att.contentType),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconFor(att.contentType),
                color: _iconFg(att.contentType),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    att.title.isEmpty ? 'Attachment' : att.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(att),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              att.isDownloadable
                  ? Icons.download_outlined
                  : Icons.hourglass_top,
              color: AppColors.textSubtle,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  static String _subtitle(ClinicalAttachment a) {
    final pieces = <String>[];
    if (a.contentType.isNotEmpty) pieces.add(a.contentType);
    if (a.sizeBytes > 0) pieces.add(_humanSize(a.sizeBytes));
    if (!a.isDownloadable) pieces.add('fetching…');
    return pieces.join(' · ');
  }

  static String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static IconData _iconFor(String ct) {
    if (ct.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (ct.startsWith('image/')) return Icons.image_outlined;
    if (ct.contains('html')) return Icons.code;
    if (ct.contains('xml')) return Icons.code;
    if (ct.contains('text/')) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  static Color _iconBg(String ct) {
    if (ct.contains('pdf')) return const Color(0xFFFCE4E4);
    if (ct.startsWith('image/')) return const Color(0xFFE6F0FB);
    return const Color(0xFFEEF1F4);
  }

  static Color _iconFg(String ct) {
    if (ct.contains('pdf')) return const Color(0xFFA42D2D);
    if (ct.startsWith('image/')) return const Color(0xFF1B5FA8);
    return AppColors.navy700;
  }
}
