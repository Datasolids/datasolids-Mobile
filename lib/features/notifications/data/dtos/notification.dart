// DTOs for the notifications API.
//
// Backend endpoints:
//   GET    /api/v1/notifications/                       list + unread_count
//   GET    /api/v1/notifications/{id}/                  detail
//   POST   /api/v1/notifications/{id}/read/             mark read
//   POST   /api/v1/notifications/{id}/unread/           mark unread
//   POST   /api/v1/notifications/{id}/archive/          archive
//   POST   /api/v1/notifications/mark-all-read/         bulk
//   POST   /api/v1/notifications/devices/register/      register push token

enum NotificationKind {
  securitySignin,
  syncCompleted,
  labResult,
  grantAccessed,
  researchOpportunity,
  appUpdate,
  generic;

  static NotificationKind parse(String raw) {
    switch (raw) {
      case 'security_signin': return NotificationKind.securitySignin;
      case 'sync_completed': return NotificationKind.syncCompleted;
      case 'lab_result': return NotificationKind.labResult;
      case 'grant_accessed': return NotificationKind.grantAccessed;
      case 'research_opportunity': return NotificationKind.researchOpportunity;
      case 'app_update': return NotificationKind.appUpdate;
      default: return NotificationKind.generic;
    }
  }

  String get eyebrowLabel {
    switch (this) {
      case NotificationKind.securitySignin: return 'SECURITY';
      case NotificationKind.syncCompleted: return 'SYNC COMPLETED';
      case NotificationKind.labResult: return 'NEW LAB RESULT';
      case NotificationKind.grantAccessed: return 'GRANT ACCESSED';
      case NotificationKind.researchOpportunity: return 'RESEARCH';
      case NotificationKind.appUpdate: return 'APP UPDATE';
      case NotificationKind.generic: return 'NOTIFICATION';
    }
  }
}


class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    required this.isRead,
    required this.isArchived,
    this.readAt,
    this.archivedAt,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? archivedAt;
  final bool isRead;
  final bool isArchived;

  factory NotificationItem.fromJson(Map<String, dynamic> j) {
    return NotificationItem(
      id: (j['id'] ?? '').toString(),
      kind: NotificationKind.parse((j['kind'] ?? '').toString()),
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      data: (j['data'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.tryParse(
        (j['created_at'] ?? '').toString(),
      )?.toLocal() ?? DateTime.now(),
      readAt: DateTime.tryParse((j['read_at'] ?? '').toString())?.toLocal(),
      archivedAt: DateTime.tryParse(
        (j['archived_at'] ?? '').toString(),
      )?.toLocal(),
      isRead: j['is_read'] as bool? ?? false,
      isArchived: j['is_archived'] as bool? ?? false,
    );
  }
}


/// Combined response shape from GET /notifications/. The unread count is
/// independent of the (possibly filtered/paginated) results list so the
/// bell badge stays accurate.
class NotificationFeed {
  const NotificationFeed({
    required this.results,
    required this.unreadCount,
    required this.total,
  });

  final List<NotificationItem> results;
  final int unreadCount;
  final int total;

  factory NotificationFeed.fromJson(Map<String, dynamic> j) =>
      NotificationFeed(
        results: ((j['results'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(NotificationItem.fromJson)
            .toList(),
        unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}
