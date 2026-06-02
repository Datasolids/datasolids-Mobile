// All diagnostic reports across categories (LAB / RAD / PAT / …).
// Wired to the My Pod Explorer's "Diagnostic Reports" tile. Distinct
// from LabsListScreen (which filters to category=LAB).

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:datasolids_mobile/features/pod/presentation/controllers/clinical_extra_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


const Color _kAccent = Color(0xFF0891B2); // cyan — matches My Pod tile


class DiagnosticReportsListScreen extends ConsumerStatefulWidget {
  const DiagnosticReportsListScreen({super.key});
  @override
  ConsumerState<DiagnosticReportsListScreen> createState() =>
      _DiagnosticReportsListScreenState();
}

class _DiagnosticReportsListScreenState
    extends ConsumerState<DiagnosticReportsListScreen> {
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
      ref.read(allDiagnosticReportsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(allDiagnosticReportsControllerProvider);
    final notifier =
        ref.read(allDiagnosticReportsControllerProvider.notifier);

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
                    active: state.categoryFilter,
                    onTap: notifier.setCategoryFilter,
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
                      (context, i) => _ReportRow(
                        item: state.items[i],
                        onTap: () => context.push(
                          '/pod/clinical/diagnostic-report/${state.items[i].id}',
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
                'Diagnostic Reports',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                total == 1 ? '1 report' : '$total reports',
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
// Category chips: All / LAB / RAD / PAT
// ─────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onTap});
  final String active;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _Chip(label: 'All', selected: active == 'all', onTap: () => onTap('all')),
          const SizedBox(width: 10),
          _Chip(label: 'Labs', selected: active == 'LAB', onTap: () => onTap('LAB')),
          const SizedBox(width: 10),
          _Chip(label: 'Radiology', selected: active == 'RAD', onTap: () => onTap('RAD')),
          const SizedBox(width: 10),
          _Chip(label: 'Pathology', selected: active == 'PAT', onTap: () => onTap('PAT')),
        ],
      ),
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

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.item, required this.onTap});
  final DiagnosticReportSummary item;
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
                child: Icon(Icons.assignment_outlined, color: _kAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? 'Report' : item.title,
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
              if (item.category.isNotEmpty)
                _CategoryPill(code: item.category),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: AppColors.textSubtle),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(DiagnosticReportSummary item) {
    final pieces = <String>[];
    if (item.resultCount > 0) {
      pieces.add('${item.resultCount} result${item.resultCount == 1 ? '' : 's'}');
    }
    if (item.status.isNotEmpty) pieces.add(item.status);
    if (item.date != null) pieces.add(_formatShortDate(item.date!));
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

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: _kAccent,
        ),
      ),
    );
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
            Icon(Icons.cloud_off_outlined,
                color: AppColors.textMuted, size: 32),
            const SizedBox(height: 10),
            Text("Couldn't load reports",
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
            child: Icon(Icons.assignment_outlined, color: _kAccent, size: 30),
          ),
          const SizedBox(height: 14),
          Text('No reports yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
              )),
          const SizedBox(height: 6),
          Text(
            'Diagnostic reports (labs, radiology reads, pathology) will appear here once your provider data is synced.',
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
