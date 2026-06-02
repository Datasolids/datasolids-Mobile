// My Pod Explorer — the tab shown when the user taps "My Pod" in the
// bottom nav. Surfaces every category we know about (not just the four in
// the original mock) plus a Recent Documents list.
//
// Bound to GET /pods/me/categories/ via podCategoriesControllerProvider.
// Pull-to-refresh re-fetches. Loading / error / empty / populated states
// are all handled here so the home_screen.dart tab switch stays trivial.

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/pod_categories.dart';
import 'package:datasolids_mobile/features/pod/presentation/controllers/pod_categories_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyPodExplorerTab extends ConsumerWidget {
  const MyPodExplorerTab({super.key, this.onBackToHome});

  /// Optional — wired up from the parent so the design's back arrow
  /// flips back to the Home tab. If omitted, the arrow is hidden.
  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(podCategoriesControllerProvider);
    final summary = state.summary;

    return RefreshIndicator(
      color: AppColors.teal600,
      onRefresh: () =>
          ref.read(podCategoriesControllerProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExplorerHeader(
              total: summary?.totalResources ?? 0,
              onBack: onBackToHome,
            ),
            const SizedBox(height: 16),
            const _ExplorerSearchBar(),
            const SizedBox(height: 22),
            if (summary == null && state.isLoading)
              const _LoadingBlock()
            else if (summary == null)
              _ErrorBlock(
                onRetry: () => ref
                    .read(podCategoriesControllerProvider.notifier)
                    .refresh(),
              )
            else if (summary.isEmpty)
              const _EmptyExplorer()
            else ...[
              _CategoryGrid(tiles: summary.categories),
              if (summary.recentDocuments.isNotEmpty) ...[
                const SizedBox(height: 28),
                const _SectionTitle('RECENT DOCUMENTS'),
                const SizedBox(height: 12),
                for (final doc in summary.recentDocuments) ...[
                  _RecentDocumentCard(doc: doc),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header — back arrow + title + total count
// ─────────────────────────────────────────────────────────────────

class _ExplorerHeader extends StatelessWidget {
  const _ExplorerHeader({required this.total, this.onBack});

  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(Icons.arrow_back, color: AppColors.navy900, size: 22),
            ),
          if (onBack != null) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Pod Explorer',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatCount(total)} total health resources',
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
      ),
    );
  }

  static String _formatCount(int n) {
    // 1,234 style — basic locale-free thousand grouping.
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────────────────
// Search bar — UI placeholder for now; tap to show "coming soon" SnackBar
// ─────────────────────────────────────────────────────────────────

class _ExplorerSearchBar extends StatelessWidget {
  const _ExplorerSearchBar();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Full-pod search is coming soon. Tap a tile to explore.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.textSubtle, size: 20),
            const SizedBox(width: 10),
            Text(
              'Search records, labs, meds…',
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
// Category grid — 2-column, every tile from the backend
// ─────────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.tiles});
  final List<PodCategoryTile> tiles;

  @override
  Widget build(BuildContext context) {
    // GridView.builder inside a SingleChildScrollView needs shrinkWrap + a
    // NeverScrollable physics so it lays out without owning scroll.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, i) => _CategoryTile(tile: tiles[i]),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.tile});
  final PodCategoryTile tile;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForKey(tile.key);

    return InkWell(
      onTap: () => context.push('/pod/category/${tile.key}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconFor(tile.icon),
                color: accent,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              tile.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tile.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Map the backend icon hint → Material icon. Unknown keys fall back to
  // a generic folder icon so a future backend tile renders something.
  static IconData _iconFor(String hint) {
    switch (hint) {
      case 'flask':
        return Icons.science_outlined;
      case 'pill':
        return Icons.medication_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'heart_pulse':
        return Icons.monitor_heart_outlined;
      case 'heart':
        return Icons.favorite_outline;
      case 'alert':
        return Icons.warning_amber_outlined;
      case 'shield':
        return Icons.shield_outlined;
      case 'stethoscope':
        return Icons.medical_services_outlined;
      case 'scalpel':
        return Icons.cut_outlined;
      case 'document':
        return Icons.description_outlined;
      case 'clipboard':
        return Icons.assignment_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  // Color the icon chip per category so the grid scans quickly.
  // Soft, on-brand palette — no harsh saturation.
  static Color _accentForKey(String key) {
    switch (key) {
      case 'labs':
        return const Color(0xFF6366F1); // indigo
      case 'medications':
        return const Color(0xFFEA580C); // orange
      case 'imaging':
        return const Color(0xFFA855F7); // purple
      case 'vitals':
        return const Color(0xFF16A34A); // green
      case 'conditions':
        return const Color(0xFFDC2626); // red
      case 'allergies':
        return const Color(0xFFF59E0B); // amber
      case 'immunizations':
        return const Color(0xFF0EA5E9); // sky
      case 'encounters':
        return AppColors.teal600;
      case 'procedures':
        return const Color(0xFF8B5CF6); // violet
      case 'documents':
        return AppColors.navy700;
      case 'diagnostic_reports':
        return const Color(0xFF0891B2); // cyan
      default:
        return AppColors.navy700;
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Recent documents
// ─────────────────────────────────────────────────────────────────

class _RecentDocumentCard extends StatelessWidget {
  const _RecentDocumentCard({required this.doc});
  final PodRecentDocument doc;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/pod/resource/${doc.id}'),
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
                color: AppColors.navy700.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.description_outlined,
                color: AppColors.navy700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title.isEmpty ? 'Document' : doc.title,
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
                    _subtitleLine(doc),
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
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSubtle,
            ),
          ],
        ),
      ),
    );
  }

  static String _subtitleLine(PodRecentDocument d) {
    final dateStr = d.date != null ? _formatShortDate(d.date!) : '';
    if (d.subtitle.isEmpty) return dateStr;
    if (dateStr.isEmpty) return d.subtitle;
    return '${d.subtitle} • $dateStr';
  }

  static String _formatShortDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────
// Section header (matches Home screen styling)
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

// ─────────────────────────────────────────────────────────────────
// Loading / error / empty states
// ─────────────────────────────────────────────────────────────────

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.navy900.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            "Couldn't load your pod",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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

class _EmptyExplorer extends StatelessWidget {
  const _EmptyExplorer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
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
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.teal500.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.folder_open_outlined,
                color: AppColors.teal600, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Your pod is empty',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect a provider to start pulling in your records.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () => context.push('/connect'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline,
                  size: 18, color: Colors.white),
              label: const Text(
                'Connect a provider',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
