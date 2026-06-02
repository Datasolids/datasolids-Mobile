// Aggregated home-dashboard data from GET /api/v1/pods/me/summary/.
// Tolerant of missing fields so the screen degrades gracefully if the
// backend is older or a section is empty.

class DashboardSource {
  const DashboardSource({
    required this.id,
    required this.sourceSystem,
    required this.sourceFlavour,
    required this.displayName,
    required this.status,
  });

  final String id;
  final String sourceSystem;
  final String sourceFlavour;
  final String displayName;
  final String status;

  /// Single-letter badge for the Pod Status card (E / C / A …).
  String get badge {
    final n = displayName.trim().isNotEmpty
        ? displayName.trim()
        : sourceSystem.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  factory DashboardSource.fromJson(Map<String, dynamic> j) => DashboardSource(
        id: (j['id'] ?? '').toString(),
        sourceSystem: (j['source_system'] ?? '').toString(),
        sourceFlavour: (j['source_flavour'] ?? '').toString(),
        displayName: (j['display_name'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
      );
}

class DashboardActivity {
  const DashboardActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    this.timestamp,
  });

  final String type; // "sync" | "grant"
  final String title;
  final String subtitle;
  final String status;
  final DateTime? timestamp;

  factory DashboardActivity.fromJson(Map<String, dynamic> j) =>
      DashboardActivity(
        type: (j['type'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        timestamp:
            DateTime.tryParse((j['timestamp'] ?? '').toString())?.toLocal(),
      );
}

class DashboardSummary {
  const DashboardSummary({
    required this.status,
    required this.encrypted,
    required this.totalResources,
    required this.completenessScore,
    required this.activeConnections,
    required this.sources,
    required this.recentActivity,
    this.lastSyncedAt,
  });

  final String status;
  final bool encrypted;
  final int totalResources;
  final int completenessScore;
  final int activeConnections;
  final List<DashboardSource> sources;
  final List<DashboardActivity> recentActivity;
  final DateTime? lastSyncedAt;

  /// First-time / empty pod: nothing connected and nothing ingested yet.
  /// Drives whether the Home screen shows the "Your pod is ready" onboarding
  /// state or the populated Pod Status card.
  bool get isEmpty => activeConnections == 0 && totalResources == 0;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final pod = (json['pod'] as Map<String, dynamic>?) ?? const {};
    final conns = (json['connections'] as Map<String, dynamic>?) ?? const {};
    final sourcesJson = (conns['sources'] as List<dynamic>?) ?? const [];
    final activityJson = (json['recent_activity'] as List<dynamic>?) ?? const [];
    return DashboardSummary(
      status: (pod['status'] ?? '').toString(),
      encrypted: pod['encrypted'] as bool? ?? true,
      totalResources: (pod['total_resources'] as num?)?.toInt() ?? 0,
      completenessScore: (pod['completeness_score'] as num?)?.toInt() ?? 0,
      lastSyncedAt:
          DateTime.tryParse((pod['last_synced_at'] ?? '').toString())?.toLocal(),
      activeConnections: (conns['active_count'] as num?)?.toInt() ?? 0,
      sources: sourcesJson
          .whereType<Map<String, dynamic>>()
          .map(DashboardSource.fromJson)
          .toList(),
      recentActivity: activityJson
          .whereType<Map<String, dynamic>>()
          .map(DashboardActivity.fromJson)
          .toList(),
    );
  }
}
