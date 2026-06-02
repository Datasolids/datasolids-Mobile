// Documents list — typed clinical endpoint.
// /clinical/document-references/ — clinical notes, discharge summaries,
// scanned forms. Tap → DocumentReferenceDetailScreen (downloadable PDFs).

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:datasolids_mobile/features/pod/presentation/controllers/clinical_extra_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


const Color _kAccent = Color(0xFF2C5282); // navy — matches My Pod tile


class DocumentsListScreen extends ConsumerStatefulWidget {
  const DocumentsListScreen({super.key});
  @override
  ConsumerState<DocumentsListScreen> createState() =>
      _DocumentsListScreenState();
}

class _DocumentsListScreenState
    extends ConsumerState<DocumentsListScreen> {
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
      ref.read(documentReferencesControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentReferencesControllerProvider);
    final notifier =
        ref.read(documentReferencesControllerProvider.notifier);

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
                    active: state.statusFilter,
                    onTap: notifier.setStatusFilter,
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

  List<Widget> _buildGroupedSlivers(
    List<DocumentReferenceSummary> items, BuildContext context,
  ) {
    final widgets = <Widget>[];
    String? currentGroup;
    for (final item in items) {
      final g = _monthGroup(item.date);
      if (g != currentGroup) {
        currentGroup = g;
        widgets.add(_GroupHeader(label: currentGroup!.toUpperCase()));
      }
      widgets.add(_DocRow(
        item: item,
        onTap: () => context.push(
          '/pod/clinical/document-reference/${item.id}',
        ),
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

  static String _monthGroup(DateTime? d) {
    if (d == null) return 'Undated';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
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
                'Documents',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                total == 1 ? '1 document' : '$total documents',
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
// Filter chips: All / Current / Superseded
// ─────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onTap});
  final String active;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: 'All',        selected: active == 'all',        onTap: () => onTap('all')),
        const SizedBox(width: 10),
        _Chip(label: 'Current',    selected: active == 'current',    onTap: () => onTap('current')),
        const SizedBox(width: 10),
        _Chip(label: 'Superseded', selected: active == 'superseded', onTap: () => onTap('superseded')),
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
// Group + row
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

class _DocRow extends StatelessWidget {
  const _DocRow({required this.item, required this.onTap});
  final DocumentReferenceSummary item;
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
                child: Icon(
                  Icons.description_outlined,
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
                      item.title.isEmpty ? 'Document' : item.title,
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
              if (item.attachmentCount > 0)
                _AttachmentBadge(count: item.attachmentCount),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: AppColors.textSubtle),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(DocumentReferenceSummary d) {
    final pieces = <String>[];
    if (d.primaryCategory.isNotEmpty) pieces.add(d.primaryCategory);
    if (d.date != null) pieces.add(_formatShortDate(d.date!));
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

class _AttachmentBadge extends StatelessWidget {
  const _AttachmentBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4E4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file, size: 11, color: Color(0xFFA42D2D)),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFA42D2D),
            ),
          ),
        ],
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
            Icon(Icons.cloud_off_outlined, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 10),
            Text("Couldn't load documents",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy900,
                )),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry',
                  style: TextStyle(color: _kAccent, fontWeight: FontWeight.w700)),
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
            child: Icon(Icons.description_outlined, color: _kAccent, size: 30),
          ),
          const SizedBox(height: 14),
          Text('No documents yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
              )),
          const SizedBox(height: 6),
          Text(
            'Connect a provider that exposes clinical notes or discharge summaries.',
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
