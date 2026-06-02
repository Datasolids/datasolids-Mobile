// Per-category resource list item from GET /pods/me/categories/<key>/resources/
// and the resource detail from GET /pods/me/resources/<id>/.
//
// DTOs are tolerant of missing fields so the screen still renders if the
// backend is older or a particular FHIR resource is missing a field.

/// Status pill — drives the colored chip on the row ("NORMAL", "HIGH", "CRITICAL", …).
class CategoryResourceStatus {
  const CategoryResourceStatus({
    required this.code,
    required this.label,
    required this.severity,
  });

  /// Raw status code: 'N', 'H', 'AA', 'active', 'completed', etc.
  final String code;

  /// Display label — "NORMAL", "CRITICAL", "ACTIVE", etc.
  final String label;

  /// One of: 'normal' | 'info' | 'warning' | 'danger' | 'muted'.
  /// The mobile screen maps this to a pill color.
  final String severity;

  bool get hasLabel => label.trim().isNotEmpty;

  factory CategoryResourceStatus.fromJson(Map<String, dynamic>? j) {
    final m = j ?? const {};
    return CategoryResourceStatus(
      code: (m['code'] ?? '').toString(),
      label: (m['label'] ?? '').toString(),
      severity: (m['severity'] ?? 'muted').toString(),
    );
  }
}

class CategoryResourceListItem {
  const CategoryResourceListItem({
    required this.id,
    required this.fhirResourceType,
    required this.title,
    required this.subtitle,
    required this.groupLabel,
    required this.status,
    this.date,
  });

  final String id;
  final String fhirResourceType;
  final String title;
  final String subtitle;
  final String groupLabel; // "October 2023" — server-computed
  final CategoryResourceStatus status;
  final DateTime? date;

  factory CategoryResourceListItem.fromJson(Map<String, dynamic> j) =>
      CategoryResourceListItem(
        id: (j['id'] ?? '').toString(),
        fhirResourceType: (j['fhir_resource_type'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
        groupLabel: (j['group_label'] ?? 'Undated').toString(),
        status: CategoryResourceStatus.fromJson(
          j['status'] as Map<String, dynamic>?,
        ),
        date: DateTime.tryParse((j['date'] ?? '').toString())?.toLocal(),
      );
}

/// One page of a category list — supports offset-based infinite scroll.
class CategoryResourcesPage {
  const CategoryResourcesPage({
    required this.category,
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
    required this.results,
  });

  final String category;
  final int total;
  final int offset;
  final int limit;
  final bool hasMore;
  final List<CategoryResourceListItem> results;

  factory CategoryResourcesPage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>?) ?? const [];
    return CategoryResourcesPage(
      category: (json['category'] ?? '').toString(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      results: results
          .whereType<Map<String, dynamic>>()
          .map(CategoryResourceListItem.fromJson)
          .toList(),
    );
  }
}

/// One {label, value} row in the resource-detail structured summary.
class ResourceSummaryRow {
  const ResourceSummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  factory ResourceSummaryRow.fromJson(Map<String, dynamic> j) =>
      ResourceSummaryRow(
        label: (j['label'] ?? '').toString(),
        value: (j['value'] ?? '').toString(),
      );
}

/// Detail-screen payload — structured summary on top, raw FHIR payload below.
class ResourceDetail {
  const ResourceDetail({
    required this.id,
    required this.fhirResourceType,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.summary,
    required this.payload,
    this.date,
    this.sourceSystem,
  });

  final String id;
  final String fhirResourceType;
  final String title;
  final String subtitle;
  final CategoryResourceStatus status;
  final List<ResourceSummaryRow> summary;
  final Map<String, dynamic> payload; // raw FHIR JSON
  final DateTime? date;
  final String? sourceSystem;

  factory ResourceDetail.fromJson(Map<String, dynamic> j) {
    final summaryRaw = (j['summary'] as List<dynamic>?) ?? const [];
    return ResourceDetail(
      id: (j['id'] ?? '').toString(),
      fhirResourceType: (j['fhir_resource_type'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      subtitle: (j['subtitle'] ?? '').toString(),
      sourceSystem: j['source_system']?.toString(),
      status: CategoryResourceStatus.fromJson(
        j['status'] as Map<String, dynamic>?,
      ),
      summary: summaryRaw
          .whereType<Map<String, dynamic>>()
          .map(ResourceSummaryRow.fromJson)
          .toList(),
      payload: (j['payload'] as Map<String, dynamic>?) ?? const {},
      date: DateTime.tryParse((j['date'] ?? '').toString())?.toLocal(),
    );
  }
}
