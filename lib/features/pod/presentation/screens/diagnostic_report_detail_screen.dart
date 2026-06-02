// Detail screen for one DiagnosticReport (e.g. a lab panel).
//
// Top: hero card with title + status + date.
// Middle: RESULTS — one row per child Observation (name / value / unit /
//          status pill / reference range).
// Bottom: ATTACHMENTS — downloadable files (PDF/HTML/PNG).
//
// Bound to `diagnosticReportDetailProvider(id)`.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:datasolids_mobile/features/pod/presentation/controllers/clinical_lab_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';


class DiagnosticReportDetailScreen extends ConsumerWidget {
  const DiagnosticReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(diagnosticReportDetailProvider(reportId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Text(
          'Lab report',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.navy900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorBlock(
            onRetry: () =>
                ref.invalidate(diagnosticReportDetailProvider(reportId)),
          ),
          data: (detail) => _Body(detail: detail),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.detail});
  final DiagnosticReportDetail detail;

  @override
  Widget build(BuildContext context) {
    final dateStr = detail.date != null ? _formatLong(detail.date!) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroCard(detail: detail, dateStr: dateStr),

          if (detail.conclusion.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionTitle('CONCLUSION'),
            const SizedBox(height: 10),
            _NoteCard(text: detail.conclusion),
          ],

          if (detail.results.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionTitle('RESULTS'),
            const SizedBox(height: 10),
            _ResultsCard(results: detail.results),
          ],

          if (detail.attachments.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionTitle('ATTACHMENTS'),
            const SizedBox(height: 10),
            for (final a in detail.attachments) ...[
              _AttachmentRow(att: a),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  static String _formatLong(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.detail, required this.dateStr});
  final DiagnosticReportDetail detail;
  final String dateStr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (detail.status.isNotEmpty) _StatusBadge(status: detail.status),
              if (dateStr.isNotEmpty) ...[
                if (detail.status.isNotEmpty) const SizedBox(width: 10),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detail.title.isEmpty ? 'Lab report' : detail.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          if (detail.category.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail.category,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSubtle,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Results
// ─────────────────────────────────────────────────────────────────

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.results});
  final List<ClinicalLabResult> results;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < results.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border.withOpacity(0.45),
              ),
            _ResultRow(result: results[i]),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});
  final ClinicalLabResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
              ),
              if (result.interpretation.isNotEmpty)
                _SeverityPill(severity: result.severity,
                              label: result.interpretation),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.value ?? '—',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                ),
              ),
              if ((result.unit ?? '').isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    result.unit!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSubtle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if ((result.referenceRange ?? '').isNotEmpty)
                Text(
                  'Range: ${result.referenceRange}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.severity, required this.label});
  final String severity;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: fg,
        ),
      ),
    );
  }

  static (Color, Color) _colors(String s) {
    switch (s) {
      case 'normal':
        return (const Color(0xFFE6F4EA), const Color(0xFF1B7F3A));
      case 'info':
        return (const Color(0xFFE6F0FB), const Color(0xFF1B5FA8));
      case 'warning':
        return (const Color(0xFFFFF4DA), const Color(0xFFA15C00));
      case 'danger':
        return (const Color(0xFFFCE4E4), const Color(0xFFA42D2D));
      default:
        return (const Color(0xFFEEF1F4), AppColors.textMuted);
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Conclusion
// ─────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.navy900,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Attachments
// ─────────────────────────────────────────────────────────────────

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.att});
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
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
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
              att.isDownloadable ? Icons.download_outlined : Icons.hourglass_top,
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

// ─────────────────────────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: AppColors.textSubtle,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colorsFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: fg,
        ),
      ),
    );
  }

  static (Color, Color) _colorsFor(String s) {
    switch (s.toLowerCase()) {
      case 'final':
        return (const Color(0xFFE6F4EA), const Color(0xFF1B7F3A));
      case 'preliminary':
        return (const Color(0xFFE6F0FB), const Color(0xFF1B5FA8));
      case 'amended':
      case 'corrected':
        return (const Color(0xFFFFF4DA), const Color(0xFFA15C00));
      case 'cancelled':
        return (const Color(0xFFFCE4E4), const Color(0xFFA42D2D));
      default:
        return (const Color(0xFFEEF1F4), AppColors.textMuted);
    }
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, color: AppColors.textMuted, size: 32),
          const SizedBox(height: 10),
          Text(
            "Couldn't load this report",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                color: AppColors.teal600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
