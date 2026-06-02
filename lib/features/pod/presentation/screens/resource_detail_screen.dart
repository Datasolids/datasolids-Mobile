// Generic resource detail screen. Works for any FHIR resource — Labs,
// Medications, Conditions, etc. — because the backend extracts a typed
// `summary` of {label, value} rows.
//
// Layout:
//   1. Header — title + subtitle + status pill
//   2. Structured summary card — rows from `summary` (Value, Reference Range,
//      Status, Date, Provider, Notes, …)
//   3. Source meta card — Source system, FHIR resource type, internal id
//   4. Collapsible "View raw FHIR" — full payload, pretty-printed
//
// Bound to `resourceDetailProvider(resourceId)`.

import 'dart:convert';

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/category_resource.dart';
import 'package:datasolids_mobile/features/pod/presentation/controllers/category_resources_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResourceDetailScreen extends ConsumerWidget {
  const ResourceDetailScreen({super.key, required this.resourceId});

  final String resourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(resourceDetailProvider(resourceId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Text(
          'Record',
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
            onRetry: () => ref.invalidate(resourceDetailProvider(resourceId)),
          ),
          data: (detail) => _DetailBody(detail: detail),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────

class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.detail});
  final ResourceDetail detail;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  bool _rawExpanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final dateStr = d.date != null ? _formatLongDate(d.date!) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ----- Hero header -----
          _HeroCard(detail: d, dateStr: dateStr),

          // ----- Structured summary -----
          if (d.summary.isNotEmpty) ...[
            const SizedBox(height: 18),
            _SectionTitle('DETAILS'),
            const SizedBox(height: 10),
            _SummaryCard(rows: d.summary),
          ],

          // ----- Source meta -----
          const SizedBox(height: 18),
          _SectionTitle('SOURCE'),
          const SizedBox(height: 10),
          _SourceCard(detail: d),

          // ----- Raw FHIR (collapsed by default) -----
          const SizedBox(height: 18),
          _RawFhirCard(
            payload: d.payload,
            expanded: _rawExpanded,
            onToggle: () => setState(() => _rawExpanded = !_rawExpanded),
          ),
        ],
      ),
    );
  }

  static String _formatLongDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────
// Hero — title, subtitle, status pill, date
// ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.detail, required this.dateStr});

  final ResourceDetail detail;
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
              if (detail.status.hasLabel) _StatusPill(status: detail.status),
              if (dateStr.isNotEmpty) ...[
                if (detail.status.hasLabel) const SizedBox(width: 10),
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
            detail.title.isEmpty ? 'Record' : detail.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          if (detail.subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Summary card — {label, value} rows
// ─────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});
  final List<ResourceSummaryRow> rows;

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
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border.withOpacity(0.45),
              ),
            _SummaryRowTile(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _SummaryRowTile extends StatelessWidget {
  const _SummaryRowTile({required this.row});
  final ResourceSummaryRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              row.label,
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
              row.value.isEmpty ? '—' : row.value,
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

// ─────────────────────────────────────────────────────────────────
// Source meta card
// ─────────────────────────────────────────────────────────────────

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.detail});
  final ResourceDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = <ResourceSummaryRow>[
      if ((detail.sourceSystem ?? '').isNotEmpty)
        ResourceSummaryRow(label: 'Source', value: detail.sourceSystem!),
      ResourceSummaryRow(label: 'FHIR type', value: detail.fhirResourceType),
      ResourceSummaryRow(label: 'Internal ID', value: detail.id),
    ];
    return _SummaryCard(rows: rows);
  }
}

// ─────────────────────────────────────────────────────────────────
// Raw FHIR — pretty-printed JSON, expand-on-tap, with a copy button
// ─────────────────────────────────────────────────────────────────

class _RawFhirCard extends StatelessWidget {
  const _RawFhirCard({
    required this.payload,
    required this.expanded,
    required this.onToggle,
  });

  final Map<String, dynamic> payload;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(payload);

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  Icon(Icons.code_rounded,
                      color: AppColors.navy700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'View raw FHIR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy900,
                      ),
                    ),
                  ),
                  if (expanded)
                    IconButton(
                      icon: Icon(Icons.copy_outlined,
                          size: 18, color: AppColors.textSubtle),
                      tooltip: 'Copy JSON',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: pretty));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('FHIR JSON copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSubtle,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2742),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                pretty,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.45,
                  color: Color(0xFFE4ECF7),
                ),
              ),
            ),
        ],
      ),
    );
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final CategoryResourceStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = _colorsFor(status.severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color, Color) _colorsFor(String severity) {
    switch (severity) {
      case 'normal':
        return (const Color(0xFFE6F4EA), const Color(0xFF1B7F3A), const Color(0xFF22A05A));
      case 'info':
        return (const Color(0xFFE6F0FB), const Color(0xFF1B5FA8), const Color(0xFF3B82F6));
      case 'warning':
        return (const Color(0xFFFFF4DA), const Color(0xFFA15C00), const Color(0xFFE69500));
      case 'danger':
        return (const Color(0xFFFCE4E4), const Color(0xFFA42D2D), const Color(0xFFE0524F));
      default:
        return (const Color(0xFFEEF1F4), AppColors.textMuted, AppColors.textSubtle);
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
            "Couldn't load this record",
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
