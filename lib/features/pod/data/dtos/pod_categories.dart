// My Pod Explorer payload from GET /api/v1/pods/me/categories/.
//
// Shape:
//   {
//     "total_resources": 3240,
//     "categories": [
//       {"key": "labs", "label": "Labs", "icon": "flask",
//        "count": 142, "subtitle": "142 results"},
//       ...
//     ],
//     "recent_documents": [
//       {"id": "...", "title": "Blood Panel - Lipid Profile",
//        "subtitle": "Quest Diagnostics", "date": "2023-10-24"},
//       ...
//     ]
//   }
//
// DTOs are tolerant of missing fields so the screen still renders if the
// backend is older or a section is empty.

class PodCategoryTile {
  const PodCategoryTile({
    required this.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.subtitle,
  });

  /// Stable identifier — "labs", "vitals", "medications", etc. Used as a
  /// key for icon/color theming on the client and (eventually) as the
  /// query param when tapping through to the category detail screen.
  final String key;

  /// Display label — "Labs", "Medications", …
  final String label;

  /// Icon hint from the backend — "flask", "pill", "image", "heart_pulse",
  /// "heart", "alert", "shield", "stethoscope", "scalpel", "document",
  /// "clipboard". The screen maps these to Material icons.
  final String icon;

  /// Total non-duplicate count for the category.
  final int count;

  /// Pre-formatted secondary line — "142 results", "12 active", "8 scans".
  final String subtitle;

  factory PodCategoryTile.fromJson(Map<String, dynamic> j) => PodCategoryTile(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        icon: (j['icon'] ?? '').toString(),
        count: (j['count'] as num?)?.toInt() ?? 0,
        subtitle: (j['subtitle'] ?? '').toString(),
      );
}

class PodRecentDocument {
  const PodRecentDocument({
    required this.id,
    required this.title,
    required this.subtitle,
    this.date,
  });

  final String id;
  final String title;
  final String subtitle; // typically the provider/organisation
  final DateTime? date;

  factory PodRecentDocument.fromJson(Map<String, dynamic> j) =>
      PodRecentDocument(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
        date: DateTime.tryParse((j['date'] ?? '').toString())?.toLocal(),
      );
}

class PodCategoriesSummary {
  const PodCategoriesSummary({
    required this.totalResources,
    required this.categories,
    required this.recentDocuments,
  });

  final int totalResources;
  final List<PodCategoryTile> categories;
  final List<PodRecentDocument> recentDocuments;

  factory PodCategoriesSummary.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>?) ?? const [];
    final docs = (json['recent_documents'] as List<dynamic>?) ?? const [];
    return PodCategoriesSummary(
      totalResources: (json['total_resources'] as num?)?.toInt() ?? 0,
      categories: cats
          .whereType<Map<String, dynamic>>()
          .map(PodCategoryTile.fromJson)
          .toList(),
      recentDocuments: docs
          .whereType<Map<String, dynamic>>()
          .map(PodRecentDocument.fromJson)
          .toList(),
    );
  }

  /// Brand-new pod — nothing ingested yet. Empty state shows a different
  /// CTA ("Connect your first provider") instead of the category grid.
  bool get isEmpty => totalResources == 0;
}
