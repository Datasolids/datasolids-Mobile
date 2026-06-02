// Medications list — same scaffold as labs but medication-specific copy,
// chips, and accent. Tap a row → /pod/resource/<id> (the generic detail
// screen renders the MedicationRequest summary).
//
// Bound to `categoryResourcesControllerProvider('medications')`.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/category_resource.dart';
import 'package:datasolids_mobile/features/pod/presentation/controllers/category_resources_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const String _kCategoryKey = 'medications';
const String _kCategoryLabel = 'Medications';

// Medication accent — warm orange, matches the My Pod Explorer tile.
const Color _kAccent = Color(0xFFEA580C);

class MedicationsListScreen extends ConsumerStatefulWidget {
  const MedicationsListScreen({super.key});

  @override
  ConsumerState<MedicationsListScreen> createState() =>
      _MedicationsListScreenState();
}

class _MedicationsListScreenState
    extends ConsumerState<MedicationsListScreen> {
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
      ref
          .read(categoryResourcesControllerProvider(_kCategoryKey).notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryResourcesControllerProvider(_kCategoryKey));
    final notifier =
        ref.read(categoryResourcesControllerProvider(_kCategoryKey).notifier);

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
                sliver: SliverToBoxAdapter(
                  child: _Header(total: state.total),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                sliver: SliverToBoxAdapter(child: _SearchPlaceholder()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _FilterChips(
                    active: state.filter,
                    onTap: notifier.setFilter,
                    onSortTap: () =>
                        _openSortSheet(context, notifier, state.sort),
                  ),
                ),
              ),
              if (state.isLoadingFirstPage && state.items.isEmpty)
                const SliverToBoxAdapter(child: _LoadingBlock())
              else if (state.errorMessage != null && state.items.isEmpty)
                SliverToBoxAdapter(
                  child: _ErrorBlock(onRetry: notifier.refresh),
                )
              else if (state.items.isEmpty)
                const SliverToBoxAdapter(child: _EmptyBlock())
              else
                ..._buildGroupedSlivers(state.items, context),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(child: _LoadingMore()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Month grouping by authoredOn date
  // ─────────────────────────────────────────────────────────────────

  List<Widget> _buildGroupedSlivers(
    List<CategoryResourceListItem> items,
    BuildContext context,
  ) {
    final widgets = <Widget>[];
    String? currentGroup;
    for (final item in items) {
      if (item.groupLabel != currentGroup) {
        currentGroup = item.groupLabel;
        widgets.add(_GroupHeader(label: currentGroup!.toUpperCase()));
      }
      widgets.add(_MedicationRow(
        item: item,
        onTap: () => context.push('/pod/resource/${item.id}'),
      ));
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => widgets[i],
            childCount: widgets.length,
          ),
        ),
      ),
    ];
  }

  void _openSortSheet(
    BuildContext context,
    CategoryResourcesController notifier,
    String currentSort,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _SortRow(
                  label: 'Newest first',
                  sortKey: 'date_desc',
                  currentSort: currentSort,
                  onTap: () {
                    Navigator.pop(context);
                    notifier.setSort('date_desc');
                  },
                ),
                _SortRow(
                  label: 'Oldest first',
                  sortKey: 'date_asc',
                  currentSort: currentSort,
                  onTap: () {
                    Navigator.pop(context);
                    notifier.setSort('date_asc');
                  },
                ),
                _SortRow(
                  label: 'A–Z by name',
                  sortKey: 'title_asc',
                  currentSort: currentSort,
                  onTap: () {
                    Navigator.pop(context);
                    notifier.setSort('title_asc');
                  },
                ),
              ],
            ),
          ),
        );
      },
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
                _kCategoryLabel,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _countLabel(total),
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

  static String _countLabel(int n) =>
      n == 1 ? '1 medication' : '$n medications';
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
        width: 44,
        height: 44,
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
// Search placeholder
// ─────────────────────────────────────────────────────────────────

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication search is coming soon.'),
          duration: Duration(seconds: 2),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF1F4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.textSubtle, size: 20),
            const SizedBox(width: 10),
            Text(
              'Search medications…',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSubtle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Chips — All / Active / Past / Sort
// ─────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.active,
    required this.onTap,
    required this.onSortTap,
  });

  final String active;
  final ValueChanged<String> onTap;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _Chip(label: 'All',    selected: active == 'all',    onTap: () => onTap('all')),
          const SizedBox(width: 10),
          _Chip(label: 'Active', selected: active == 'active', onTap: () => onTap('active')),
          const SizedBox(width: 10),
          _Chip(label: 'Past',   selected: active == 'past',   onTap: () => onTap('past')),
          const SizedBox(width: 10),
          _SortChip(onTap: onSortTap),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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

class _SortChip extends StatelessWidget {
  const _SortChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_list, size: 16, color: AppColors.navy900),
            const SizedBox(width: 6),
            Text(
              'Sort',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.label,
    required this.sortKey,
    required this.currentSort,
    required this.onTap,
  });

  final String label;
  final String sortKey;
  final String currentSort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = currentSort == sortKey;
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.navy900,
        ),
      ),
      trailing: selected ? Icon(Icons.check, color: _kAccent, size: 22) : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Group header (month + year, e.g. AUGUST 2023)
// ─────────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: AppColors.textSubtle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Medication row
// ─────────────────────────────────────────────────────────────────

class _MedicationRow extends StatelessWidget {
  const _MedicationRow({required this.item, required this.onTap});
  final CategoryResourceListItem item;
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  color: _kAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
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
                      _subtitleLine(item),
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
              if (item.status.hasLabel) _StatusPill(status: item.status),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: AppColors.textSubtle),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitleLine(CategoryResourceListItem item) {
    final dateStr = item.date != null ? _formatShortDate(item.date!) : '';
    if (item.subtitle.isEmpty) return dateStr;
    if (dateStr.isEmpty) return item.subtitle;
    return '${item.subtitle} • $dateStr';
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
  const _StatusPill({required this.status});
  final CategoryResourceStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = _colorsFor(status.severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 10,
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

// ─────────────────────────────────────────────────────────────────
// Loading / error / empty
// ─────────────────────────────────────────────────────────────────

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _LoadingMore extends StatelessWidget {
  const _LoadingMore();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: SizedBox(
          height: 18, width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
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
            Text(
              "Couldn't load medications",
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
                  color: _kAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.medication_outlined,
                color: _kAccent, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'No medications yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect a provider that has medication data, '
            'then come back here.',
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
