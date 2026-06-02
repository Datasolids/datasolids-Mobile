// Detail screen for one DocumentReference. Hero card → DETAILS table →
// ATTACHMENTS list with tap-to-download (presigned S3 URLs).

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:datasolids_mobile/features/pod/presentation/controllers/clinical_extra_controllers.dart';
import 'package:datasolids_mobile/features/pod/presentation/widgets/clinical_attachment_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class DocumentReferenceDetailScreen extends ConsumerWidget {
  const DocumentReferenceDetailScreen({super.key, required this.docRefId});

  final String docRefId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(documentReferenceDetailProvider(docRefId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Text(
          'Document',
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
                ref.invalidate(documentReferenceDetailProvider(docRefId)),
          ),
          data: (detail) => _Body(detail: detail),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});
  final DocumentReferenceDetail detail;

  @override
  Widget build(BuildContext context) {
    final dateStr = detail.date != null ? _formatLong(detail.date!) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroCard(detail: detail, dateStr: dateStr),
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionTitle('DESCRIPTION'),
            const SizedBox(height: 10),
            _NoteCard(text: detail.description),
          ],
          const SizedBox(height: 18),
          const _SectionTitle('DETAILS'),
          const SizedBox(height: 10),
          _DetailsCard(detail: detail),
          if (detail.attachments.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionTitle('ATTACHMENTS'),
            const SizedBox(height: 10),
            for (final a in detail.attachments) ...[
              ClinicalAttachmentRow(att: a),
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
  final DocumentReferenceDetail detail;
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
            detail.title.isEmpty ? 'Document' : detail.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          if (detail.primaryCategory.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail.primaryCategory,
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

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.detail});
  final DocumentReferenceDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[];
    if (detail.typeText.isNotEmpty) rows.add(('Type', detail.typeText));
    if (detail.docStatus.isNotEmpty)
      rows.add(('Doc status', detail.docStatus.toUpperCase()));
    if (detail.attachments.isNotEmpty)
      rows.add(('Attachments', '${detail.attachments.length}'));

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No additional details for this document.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    }

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
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1, thickness: 1,
                color: AppColors.border.withOpacity(0.45),
              ),
            _Row(label: rows[i].$1, value: rows[i].$2),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.textSubtle,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.navy900,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: AppColors.textSubtle,
        ),
      );
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
      case 'current':
        return (const Color(0xFFE6F4EA), const Color(0xFF1B7F3A));
      case 'superseded':
        return (const Color(0xFFFFF4DA), const Color(0xFFA15C00));
      case 'entered-in-error':
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
          Text("Couldn't load this document",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              )),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: TextStyle(
                  color: AppColors.teal600,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}
