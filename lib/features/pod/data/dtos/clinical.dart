// DTOs for the typed /api/v1/clinical/ endpoints.
//
// These are the simplified, patient-facing shapes — distinct from the
// raw-FHIR-derived shapes in category_resource.dart. The two layers will
// coexist until every category screen is migrated to a typed endpoint.

class ClinicalAttachment {
  const ClinicalAttachment({
    required this.id,
    required this.title,
    required this.contentType,
    required this.sizeBytes,
    this.rawContentType,
    this.sourceUrl,
    this.fileUrl,
    this.sha256,
    this.fetchedAt,
  });

  final String id;
  final String title;
  final String contentType;        // e.g. application/pdf
  final String? rawContentType;
  final String? sourceUrl;
  final String? fileUrl;           // presigned/local download URL
  final String? sha256;
  final int sizeBytes;
  final DateTime? fetchedAt;

  bool get isDownloadable => (fileUrl ?? '').isNotEmpty;

  factory ClinicalAttachment.fromJson(Map<String, dynamic> j) =>
      ClinicalAttachment(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        contentType: (j['content_type'] ?? '').toString(),
        rawContentType: (j['raw_content_type'] ?? '').toString(),
        sourceUrl: (j['source_url'] ?? '').toString(),
        fileUrl: j['file_url']?.toString(),
        sha256: j['sha256']?.toString(),
        sizeBytes: (j['size_bytes'] as num?)?.toInt() ?? 0,
        fetchedAt: DateTime.tryParse(
          (j['fetched_at'] ?? '').toString(),
        )?.toLocal(),
      );
}

class ClinicalLabResult {
  const ClinicalLabResult({
    required this.id,
    required this.name,
    required this.status,
    required this.interpretation,
    this.value,
    this.unit,
    this.referenceRange,
  });

  final String id;
  final String name;
  final String? value;
  final String? unit;
  final String? referenceRange;
  final String interpretation; // N / H / HH / L / LL / A / AA
  final String status;

  /// Coarse severity bucket the UI can colour against. Derived from
  /// the interpretation code (not sent by the API).
  String get severity {
    switch (interpretation) {
      case 'N': return 'normal';
      case 'L': return 'info';
      case 'LL': return 'danger';
      case 'H': return 'warning';
      case 'HH': return 'danger';
      case 'A': return 'warning';
      case 'AA': return 'danger';
      default: return 'muted';
    }
  }

  factory ClinicalLabResult.fromJson(Map<String, dynamic> j) =>
      ClinicalLabResult(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        value: j['value']?.toString(),
        unit: j['unit']?.toString(),
        referenceRange: j['reference_range']?.toString(),
        interpretation: (j['interpretation'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
      );
}

class DiagnosticReportSummary {
  const DiagnosticReportSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.category,
    required this.resultCount,
    this.date,
  });

  final String id;
  final String title;
  final String status;          // "Final" / "Preliminary" / …
  final String category;        // "LAB" / "RAD" / …
  final int resultCount;
  final DateTime? date;

  factory DiagnosticReportSummary.fromJson(Map<String, dynamic> j) =>
      DiagnosticReportSummary(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        resultCount: (j['result_count'] as num?)?.toInt() ?? 0,
        date: DateTime.tryParse((j['date'] ?? '').toString())?.toLocal(),
      );
}

class DiagnosticReportPage {
  const DiagnosticReportPage({
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
    required this.results,
  });

  final int total;
  final int offset;
  final int limit;
  final bool hasMore;
  final List<DiagnosticReportSummary> results;

  factory DiagnosticReportPage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>?) ?? const [];
    return DiagnosticReportPage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      results: results
          .whereType<Map<String, dynamic>>()
          .map(DiagnosticReportSummary.fromJson)
          .toList(),
    );
  }
}

class DiagnosticReportDetail {
  const DiagnosticReportDetail({
    required this.id,
    required this.title,
    required this.status,
    required this.category,
    required this.conclusion,
    required this.results,
    required this.attachments,
    this.date,
  });

  final String id;
  final String title;
  final String status;
  final String category;
  final String conclusion;
  final List<ClinicalLabResult> results;
  final List<ClinicalAttachment> attachments;
  final DateTime? date;

  factory DiagnosticReportDetail.fromJson(Map<String, dynamic> j) {
    final results = (j['results'] as List<dynamic>?) ?? const [];
    final attachments = (j['attachments'] as List<dynamic>?) ?? const [];
    return DiagnosticReportDetail(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      conclusion: (j['conclusion'] ?? '').toString(),
      date: DateTime.tryParse((j['date'] ?? '').toString())?.toLocal(),
      results: results
          .whereType<Map<String, dynamic>>()
          .map(ClinicalLabResult.fromJson)
          .toList(),
      attachments: attachments
          .whereType<Map<String, dynamic>>()
          .map(ClinicalAttachment.fromJson)
          .toList(),
    );
  }
}


// ============================================================================
// Observation — Vitals + standalone lab observations
// ============================================================================


/// Row shape from /clinical/observations/ (each Observation rendered as a
/// compact card). Same shape as a child of a DR's `results` array except
/// the source endpoint scopes it to the caller's pod directly.
class ObservationRow {
  const ObservationRow({
    required this.id,
    required this.name,
    required this.status,
    required this.interpretation,
    this.value,
    this.unit,
    this.referenceRange,
  });

  final String id;
  final String name;
  final String? value;
  final String? unit;
  final String? referenceRange;
  final String interpretation;
  final String status;

  String get severity {
    switch (interpretation) {
      case 'N': return 'normal';
      case 'L': return 'info';
      case 'LL': return 'danger';
      case 'H': return 'warning';
      case 'HH': return 'danger';
      case 'A': return 'warning';
      case 'AA': return 'danger';
      default: return 'muted';
    }
  }

  factory ObservationRow.fromJson(Map<String, dynamic> j) => ObservationRow(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        value: j['value']?.toString(),
        unit: j['unit']?.toString(),
        referenceRange: j['reference_range']?.toString(),
        interpretation: (j['interpretation'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
      );
}

class ObservationPage {
  const ObservationPage({
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
    required this.results,
  });

  final int total;
  final int offset;
  final int limit;
  final bool hasMore;
  final List<ObservationRow> results;

  factory ObservationPage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>?) ?? const [];
    return ObservationPage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      results: results
          .whereType<Map<String, dynamic>>()
          .map(ObservationRow.fromJson)
          .toList(),
    );
  }
}

/// Detail shape from /clinical/observations/<id>/ — adds coding +
/// timestamps + category + notes. Used by the Vitals/Observation detail
/// screen.
class ObservationDetail {
  const ObservationDetail({
    required this.id,
    required this.name,
    required this.status,
    required this.interpretation,
    required this.category,
    required this.codeSystem,
    required this.codeValue,
    required this.notes,
    this.value,
    this.unit,
    this.referenceRange,
    this.effectiveAt,
    this.issuedAt,
  });

  final String id;
  final String name;
  final String? value;
  final String? unit;
  final String? referenceRange;
  final String interpretation;
  final String status;
  final String category;
  final String codeSystem;
  final String codeValue;
  final String notes;
  final DateTime? effectiveAt;
  final DateTime? issuedAt;

  String get severity {
    switch (interpretation) {
      case 'N': return 'normal';
      case 'L': return 'info';
      case 'LL': return 'danger';
      case 'H': return 'warning';
      case 'HH': return 'danger';
      case 'A': return 'warning';
      case 'AA': return 'danger';
      default: return 'muted';
    }
  }

  factory ObservationDetail.fromJson(Map<String, dynamic> j) =>
      ObservationDetail(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        value: j['value']?.toString(),
        unit: j['unit']?.toString(),
        referenceRange: j['reference_range']?.toString(),
        interpretation: (j['interpretation'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        codeSystem: (j['code_system'] ?? '').toString(),
        codeValue: (j['code_value'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        effectiveAt: DateTime.tryParse(
          (j['effective_at'] ?? '').toString(),
        )?.toLocal(),
        issuedAt: DateTime.tryParse(
          (j['issued_at'] ?? '').toString(),
        )?.toLocal(),
      );
}


// ============================================================================
// DocumentReference
// ============================================================================


class DocumentReferenceSummary {
  const DocumentReferenceSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.primaryCategory,
    required this.attachmentCount,
    this.date,
    this.docStatus,
  });

  final String id;
  final String title;
  final String status;
  final String? docStatus;
  final String primaryCategory;
  final int attachmentCount;
  final DateTime? date;

  factory DocumentReferenceSummary.fromJson(Map<String, dynamic> j) =>
      DocumentReferenceSummary(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        docStatus: (j['doc_status'] ?? '').toString(),
        primaryCategory: (j['primary_category'] ?? '').toString(),
        attachmentCount: (j['attachment_count'] as num?)?.toInt() ?? 0,
        date: DateTime.tryParse((j['date'] ?? '').toString())?.toLocal(),
      );
}

class DocumentReferencePage {
  const DocumentReferencePage({
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
    required this.results,
  });

  final int total;
  final int offset;
  final int limit;
  final bool hasMore;
  final List<DocumentReferenceSummary> results;

  factory DocumentReferencePage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>?) ?? const [];
    return DocumentReferencePage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      results: results
          .whereType<Map<String, dynamic>>()
          .map(DocumentReferenceSummary.fromJson)
          .toList(),
    );
  }
}

class DocumentReferenceDetail {
  const DocumentReferenceDetail({
    required this.id,
    required this.title,
    required this.status,
    required this.docStatus,
    required this.typeText,
    required this.primaryCategory,
    required this.description,
    required this.attachments,
    this.date,
  });

  final String id;
  final String title;
  final String status;
  final String docStatus;
  final String typeText;
  final String primaryCategory;
  final String description;
  final List<ClinicalAttachment> attachments;
  final DateTime? date;

  factory DocumentReferenceDetail.fromJson(Map<String, dynamic> j) {
    final attachments = (j['attachments'] as List<dynamic>?) ?? const [];
    return DocumentReferenceDetail(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      docStatus: (j['doc_status'] ?? '').toString(),
      typeText: (j['type_text'] ?? '').toString(),
      primaryCategory: (j['primary_category'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      date: DateTime.tryParse((j['date'] ?? '').toString())?.toLocal(),
      attachments: attachments
          .whereType<Map<String, dynamic>>()
          .map(ClinicalAttachment.fromJson)
          .toList(),
    );
  }
}


// ============================================================================
// ImagingStudy
// ============================================================================


class ImagingStudySummary {
  const ImagingStudySummary({
    required this.id,
    required this.title,
    required this.status,
    required this.primaryModality,
    required this.numberOfSeries,
    required this.numberOfInstances,
    required this.attachmentCount,
    this.started,
  });

  final String id;
  final String title;
  final String status;
  final String primaryModality;
  final int numberOfSeries;
  final int numberOfInstances;
  final int attachmentCount;
  final DateTime? started;

  factory ImagingStudySummary.fromJson(Map<String, dynamic> j) =>
      ImagingStudySummary(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        primaryModality: (j['primary_modality'] ?? '').toString(),
        numberOfSeries: (j['number_of_series'] as num?)?.toInt() ?? 0,
        numberOfInstances: (j['number_of_instances'] as num?)?.toInt() ?? 0,
        attachmentCount: (j['attachment_count'] as num?)?.toInt() ?? 0,
        started: DateTime.tryParse((j['started'] ?? '').toString())?.toLocal(),
      );
}

class ImagingStudyPage {
  const ImagingStudyPage({
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
    required this.results,
  });

  final int total;
  final int offset;
  final int limit;
  final bool hasMore;
  final List<ImagingStudySummary> results;

  factory ImagingStudyPage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>?) ?? const [];
    return ImagingStudyPage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      results: results
          .whereType<Map<String, dynamic>>()
          .map(ImagingStudySummary.fromJson)
          .toList(),
    );
  }
}

class ImagingStudyDetail {
  const ImagingStudyDetail({
    required this.id,
    required this.title,
    required this.status,
    required this.primaryModality,
    required this.description,
    required this.numberOfSeries,
    required this.numberOfInstances,
    required this.attachments,
    this.started,
  });

  final String id;
  final String title;
  final String status;
  final String primaryModality;
  final String description;
  final int numberOfSeries;
  final int numberOfInstances;
  final List<ClinicalAttachment> attachments;
  final DateTime? started;

  factory ImagingStudyDetail.fromJson(Map<String, dynamic> j) {
    final attachments = (j['attachments'] as List<dynamic>?) ?? const [];
    return ImagingStudyDetail(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      primaryModality: (j['primary_modality'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      numberOfSeries: (j['number_of_series'] as num?)?.toInt() ?? 0,
      numberOfInstances: (j['number_of_instances'] as num?)?.toInt() ?? 0,
      started: DateTime.tryParse((j['started'] ?? '').toString())?.toLocal(),
      attachments: attachments
          .whereType<Map<String, dynamic>>()
          .map(ClinicalAttachment.fromJson)
          .toList(),
    );
  }
}
