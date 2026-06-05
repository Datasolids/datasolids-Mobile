// Conditions list — typed clinical endpoint.
// /clinical/conditions/ → ConditionDetailScreen on tap.
// Red theme matches the My Pod tile.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:datasolids_mobile/features/pod/presentation/controllers/medication_and_condition_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


const Color _kAccent = Color(0xFFDC2626); // red — matches My Pod tile


class ConditionsListScreen extends ConsumerStatefulWidget {
  const ConditionsListScreen({super.key});
  @override
  ConsumerState<ConditionsListScreen> createState() =>
      _ConditionsListScreenState();
}

class _ConditionsListScreenState
    extends ConsumerState<ConditionsListScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }
  @override
  void dispose() {
    _scroll.removeListener(_maybeLoadMore);
    _scroll.dispose();
    super.dispose();
  }
  void _maybeLoadMore() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      ref.read(conditionsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conditionsControllerProvider);
    final notifier = ref.read(conditionsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kAccent,
          onRefresh: notifier.refresh,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                sliver: SliverToBoxAdapter(child: _Header(total: state.total)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _FilterChips(
                    active: state.filter,
                    onTap: notifier.setFilter,
                  ),
                ),
              ),
              if (state.isLoadingFirstPage && state.items.isEmpty)
                const SliverToBoxAdapter(child: _LoadingBlock())
              else if (state.errorMessage != null && state.items.isEmpty)
                SliverToBoxAdapter(child: _ErrorBlock(onRetry: notifier.refresh))
              else if (state.items.isEmpty)
                const SliverToBoxAdapter(child: _EmptyBlock())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ConditionRow(
                        item: state.items[i],
                        onTap: () => context.push(
                          '/pod/clinical/condition/${state.items[i].id}',
                        ),
                      ),
                      childCount: state.items.length,
                    ),
                  ),
                ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(child: _LoadingMore()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleBackButton(onTap: () => Navigator.of(context).pop()),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conditions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                total == 1 ? '1 condition' : '$total conditions',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: Icon(Icons.arrow_back, color: AppColors.navy900, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Filter chips: All / Active / Resolved
// ─────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onTap});
  final String active;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: 'All',      selected: active == 'all',      onTap: () => onTap('all')),
        const SizedBox(width: 10),
        _Chip(label: 'Active',   selected: active == 'active',   onTap: () => onTap('active')),
        const SizedBox(width: 10),
        _Chip(label: 'Resolved', selected: active == 'resolved', onTap: () => onTap('resolved')),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _kAccent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kAccent : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.navy900,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Row
// ─────────────────────────────────────────────────────────────────

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({required this.item, required this.onTap});
  final ConditionSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
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
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.favorite_outline, color: _kAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? 'Condition' : item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(item),
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
              _StatusPill(
                clinicalStatus: item.clinicalStatus,
                severity: item.severity,
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: AppColors.textSubtle),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(ConditionSummary c) {
    final pieces = <String>[];
    if (c.primaryCategory.isNotEmpty) pieces.add(c.primaryCategory);
    if (c.severityCode.isNotEmpty) pieces.add(c.severityCode);
    if (c.onsetAt != null) pieces.add('onset ${_formatShortDate(c.onsetAt!)}');
    return pieces.join(' • ');
  }

  static String _formatShortDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.clinicalStatus, required this.severity});
  final String clinicalStatus;
  final String severity;

  @override
  Widget build(BuildContext context) {
    if (clinicalStatus.isEmpty) return const SizedBox.shrink();
    final (bg, fg) = _colorsFor(clinicalStatus, severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        clinicalStatus.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: fg,
        ),
      ),
    );
  }

  static (Color, Color) _colorsFor(String status, String severity) {
    // Resolved / inactive / remission → muted green-gray
    final s = status.toLowerCase();
    if (s == 'resolved' || s == 'inactive' || s == 'remission') {
      return (const Color(0xFFEEF1F4), AppColors.textMuted);
    }
    // Active conditions colored by severity.
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

// ─────────────────────────────────────────────────────────────────
// Loading / error / empty
// ─────────────────────────────────────────────────────────────────

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();
  @override
  Widget build(BuildContext context) =>
      Container(height: 220, alignment: Alignment.center,
                child: const CircularProgressIndicator());
}

class _LoadingMore extends StatelessWidget {
  const _LoadingMore();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            height: 18, width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off_outlined, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 10),
            Text("Couldn't load conditions",
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
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.favorite_outline, color: _kAccent, size: 30),
          ),
          const SizedBox(height: 14),
          Text('No conditions yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
              )),
          const SizedBox(height: 6),
          Text(
            'Diagnoses and problem-list items from your providers will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
