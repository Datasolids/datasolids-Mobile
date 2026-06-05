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

// ============================================================================
// MedicationRequest
// ============================================================================


class MedicationRequestSummary {
  const MedicationRequestSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.intent,
    this.doseQuantity,
    this.doseUnit,
    this.routeText,
    this.authoredAt,
    this.requesterName,
  });

  final String id;
  final String title;
  final String status;     // active | on-hold | completed | …
  final String intent;
  final String? doseQuantity;
  final String? doseUnit;
  final String? routeText;
  final DateTime? authoredAt;
  final String? requesterName;

  bool get isActive => status.toLowerCase() == 'active';

  factory MedicationRequestSummary.fromJson(Map<String, dynamic> j) =>
      MedicationRequestSummary(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        intent: (j['intent'] ?? '').toString(),
        doseQuantity: j['dose_quantity']?.toString(),
        doseUnit: j['dose_unit']?.toString(),
        routeText: j['route_text']?.toString(),
        authoredAt:
            DateTime.tryParse((j['authored_at'] ?? '').toString())?.toLocal(),
        requesterName: j['requester_name']?.toString(),
      );
}

class MedicationRequestPage {
  const MedicationRequestPage({
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
  final List<MedicationRequestSummary> results;

  factory MedicationRequestPage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>?) ?? const [];
    return MedicationRequestPage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      results: results
          .whereType<Map<String, dynamic>>()
          .map(MedicationRequestSummary.fromJson)
          .toList(),
    );
  }
}

class MedicationRequestDetail {
  const MedicationRequestDetail({
    required this.id,
    required this.title,
    required this.status,
    required this.intent,
    required this.medicationCode,
    required this.dosageText,
    required this.notes,
    this.doseQuantity,
    this.doseUnit,
    this.routeText,
    this.refillsAllowed,
    this.quantityValue,
    this.quantityUnit,
    this.authoredAt,
    this.requesterName,
  });

  final String id;
  final String title;
  final String status;
  final String intent;
  final String medicationCode;
  final String dosageText;
  final String notes;
  final String? doseQuantity;
  final String? doseUnit;
  final String? routeText;
  final int? refillsAllowed;
  final String? quantityValue;
  final String? quantityUnit;
  final DateTime? authoredAt;
  final String? requesterName;

  factory MedicationRequestDetail.fromJson(Map<String, dynamic> j) =>
      MedicationRequestDetail(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        intent: (j['intent'] ?? '').toString(),
        medicationCode: (j['medication_code'] ?? '').toString(),
        dosageText: (j['dosage_text'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        doseQuantity: j['dose_quantity']?.toString(),
        doseUnit: j['dose_unit']?.toString(),
        routeText: j['route_text']?.toString(),
        refillsAllowed: (j['refills_allowed'] as num?)?.toInt(),
        quantityValue: j['quantity_value']?.toString(),
        quantityUnit: j['quantity_unit']?.toString(),
        authoredAt:
            DateTime.tryParse((j['authored_at'] ?? '').toString())?.toLocal(),
        requesterName: j['requester_name']?.toString(),
      );
}


// ============================================================================
// Condition
// ============================================================================


class ConditionSummary {
  const ConditionSummary({
    required this.id,
    required this.title,
    required this.clinicalStatus,
    required this.primaryCategory,
    required this.severityCode,
    this.onsetAt,
    this.recordedAt,
  });

  final String id;
  final String title;
  final String clinicalStatus;    // active | resolved | inactive | …
  final String primaryCategory;
  final String severityCode;
  final DateTime? onsetAt;
  final DateTime? recordedAt;

  bool get isActive => clinicalStatus.toLowerCase() == 'active';
  bool get isResolved => clinicalStatus.toLowerCase() == 'resolved';

  String get severity {
    switch (severityCode.toLowerCase()) {
      case 'mild':
      case '255604002':       return 'info';
      case 'moderate':
      case '6736007':         return 'warning';
      case 'severe':
      case '24484000':        return 'danger';
      default:                 return 'muted';
    }
  }

  factory ConditionSummary.fromJson(Map<String, dynamic> j) =>
      ConditionSummary(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        clinicalStatus: (j['clinical_status'] ?? '').toString(),
        primaryCategory: (j['primary_category'] ?? '').toString(),
        severityCode: (j['severity_code'] ?? '').toString(),
        onsetAt:
            DateTime.tryParse((j['onset_at'] ?? '').toString())?.toLocal(),
        recordedAt:
            DateTime.tryParse((j['recorded_at'] ?? '').toString())?.toLocal(),
      );
}

class ConditionPage {
  const ConditionPage({
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
  final List<ConditionSummary> results;

  factory ConditionPage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>?) ?? const [];
    return ConditionPage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      results: results
          .whereType<Map<String, dynamic>>()
          .map(ConditionSummary.fromJson)
          .toList(),
    );
  }
}

class ConditionDetail {
  const ConditionDetail({
    required this.id,
    required this.title,
    required this.clinicalStatus,
    required this.verificationStatus,
    required this.primaryCategory,
    required this.severityCode,
    required this.severityText,
    required this.codeSystem,
    required this.codeValue,
    required this.bodySiteText,
    required this.notes,
    this.onsetAt,
    this.abatementAt,
    this.recordedAt,
  });

  final String id;
  final String title;
  final String clinicalStatus;
  final String verificationStatus;
  final String primaryCategory;
  final String severityCode;
  final String severityText;
  final String codeSystem;
  final String codeValue;
  final String bodySiteText;
  final String notes;
  final DateTime? onsetAt;
  final DateTime? abatementAt;
  final DateTime? recordedAt;

  String get severity {
    switch (severityCode.toLowerCase()) {
      case 'mild':
      case '255604002':       return 'info';
      case 'moderate':
      case '6736007':         return 'warning';
      case 'severe':
      case '24484000':        return 'danger';
      default:                 return 'muted';
    }
  }

  factory ConditionDetail.fromJson(Map<String, dynamic> j) => ConditionDetail(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        clinicalStatus: (j['clinical_status'] ?? '').toString(),
        verificationStatus: (j['verification_status'] ?? '').toString(),
        primaryCategory: (j['primary_category'] ?? '').toString(),
        severityCode: (j['severity_code'] ?? '').toString(),
        severityText: (j['severity_text'] ?? '').toString(),
        codeSystem: (j['code_system'] ?? '').toString(),
        codeValue: (j['code_value'] ?? '').toString(),
        bodySiteText: (j['body_site_text'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        onsetAt:
            DateTime.tryParse((j['onset_at'] ?? '').toString())?.toLocal(),
        abatementAt:
            DateTime.tryParse((j['abatement_at'] ?? '').toString())?.toLocal(),
        recordedAt:
            DateTime.tryParse((j['recorded_at'] ?? '').toString())?.toLocal(),
      );
}


// ============================================================================
// (Existing) ImagingStudyDetail follows below
// ============================================================================


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
