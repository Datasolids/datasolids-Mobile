// Detail screen for one Condition. Hero (clinical status + onset date),
// DETAILS table (verification, category, severity, code, body site,
// recorded), NOTES section.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:datasolids_mobile/features/pod/presentation/controllers/medication_and_condition_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


const Color _kAccent = Color(0xFFDC2626);


class ConditionDetailScreen extends ConsumerWidget {
  const ConditionDetailScreen({super.key, required this.conditionId});

  final String conditionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conditionDetailProvider(conditionId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.navy900,
        leading: const BackButton(),
        title: Text(
          'Condition',
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
            onRetry: () => ref.invalidate(conditionDetailProvider(conditionId)),
          ),
          data: (detail) => _Body(detail: detail),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});
  final ConditionDetail detail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroCard(detail: detail),
          const SizedBox(height: 18),
          const _SectionTitle('DETAILS'),
          const SizedBox(height: 10),
          _DetailsCard(detail: detail),
          if (detail.notes.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionTitle('NOTES'),
            const SizedBox(height: 10),
            _NoteCard(text: detail.notes),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.detail});
  final ConditionDetail detail;

  @override
  Widget build(BuildContext context) {
    final onsetStr =
        detail.onsetAt != null ? 'Onset ${_formatLong(detail.onsetAt!)}' : '';
    final abateStr = detail.abatementAt != null
        ? 'Resolved ${_formatLong(detail.abatementAt!)}'
        : '';

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
              if (detail.clinicalStatus.isNotEmpty)
                _StatusBadge(
                  status: detail.clinicalStatus,
                  severity: detail.severity,
                ),
              if (detail.severityText.isNotEmpty) ...[
                if (detail.clinicalStatus.isNotEmpty) const SizedBox(width: 10),
                Text(
                  detail.severityText,
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
            detail.title.isEmpty ? 'Condition' : detail.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          if (onsetStr.isNotEmpty || abateStr.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (onsetStr.isNotEmpty)
              Text(
                onsetStr,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSubtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (abateStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  abateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSubtle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.detail});
  final ConditionDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (detail.verificationStatus.isNotEmpty)
        ('Verification', detail.verificationStatus.toUpperCase()),
      if (detail.primaryCategory.isNotEmpty)
        ('Category', detail.primaryCategory),
      if (detail.severityText.isNotEmpty || detail.severityCode.isNotEmpty)
        ('Severity', detail.severityText.isNotEmpty
            ? detail.severityText
            : detail.severityCode),
      if (detail.codeValue.isNotEmpty)
        ('Code', '${detail.codeValue}'
            '${detail.codeSystem.isNotEmpty ? '  ·  ${_shortSystem(detail.codeSystem)}' : ''}'),
      if (detail.bodySiteText.isNotEmpty) ('Body site', detail.bodySiteText),
      if (detail.recordedAt != null)
        ('Recorded', detail.recordedAt!.toLocal().toString().substring(0, 10)),
    ];

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No additional details for this condition.',
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

  static String _shortSystem(String s) {
    if (s.contains('icd-10')) return 'ICD-10';
    if (s.contains('snomed')) return 'SNOMED';
    if (s.contains('rxnorm')) return 'RxNorm';
    return s.length > 40 ? '${s.substring(0, 37)}...' : s;
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
  const _StatusBadge({required this.status, required this.severity});
  final String status;
  final String severity;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colorsFor(status, severity);
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

  static (Color, Color) _colorsFor(String status, String severity) {
    final s = status.toLowerCase();
    if (s == 'resolved' || s == 'inactive' || s == 'remission') {
      return (const Color(0xFFEEF1F4), AppColors.textMuted);
    }
    switch (severity) {
      case 'danger':
        return (const Color(0xFFFCE4E4), const Color(0xFFA42D2D));
      case 'warning':
        return (const Color(0xFFFFF4DA), const Color(0xFFA15C00));
      case 'info':
        return (const Color(0xFFE6F0FB), const Color(0xFF1B5FA8));
      default:
        return (const Color(0xFFFCE4E4), const Color(0xFFA42D2D));
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
          Text("Couldn't load this condition",
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
                  color: _kAccent, fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}
