// API client for the typed /api/v1/clinical/ endpoints.

import 'package:datasolids_mobile/core/network/dio_client.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClinicalApi {
  ClinicalApi(this._dio);
  final Dio _dio;

  // ----- DiagnosticReport ----------------------------------------------------

  Future<DiagnosticReportPage> listDiagnosticReports({
    String? category,
    String? statusFilter,
    String? q,
    int offset = 0,
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/diagnostic-reports/',
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (statusFilter != null && statusFilter.isNotEmpty) 'status': statusFilter,
        if (q != null && q.isNotEmpty) 'q': q,
        'offset': offset,
        'limit': limit,
      },
    );
    return DiagnosticReportPage.fromJson(resp.data ?? const {});
  }

  Future<DiagnosticReportDetail> getDiagnosticReport(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/diagnostic-reports/$id/',
    );
    return DiagnosticReportDetail.fromJson(resp.data ?? const {});
  }

  // ----- Observation (Vitals + standalone labs) ----------------------------

  Future<ObservationPage> listObservations({
    String? category,           // 'laboratory' | 'vital-signs' | …
    String? statusFilter,
    String? code,               // LOINC code_value match
    String? interpretation,     // N | H | HH | L | LL | A | AA
    String? q,
    int offset = 0,
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/observations/',
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (statusFilter != null && statusFilter.isNotEmpty) 'status': statusFilter,
        if (code != null && code.isNotEmpty) 'code': code,
        if (interpretation != null && interpretation.isNotEmpty)
          'interpretation': interpretation,
        if (q != null && q.isNotEmpty) 'q': q,
        'offset': offset,
        'limit': limit,
      },
    );
    return ObservationPage.fromJson(resp.data ?? const {});
  }

  Future<ObservationDetail> getObservation(String id) async {
    final resp =
        await _dio.get<Map<String, dynamic>>('/clinical/observations/$id/');
    return ObservationDetail.fromJson(resp.data ?? const {});
  }

  // ----- DocumentReference --------------------------------------------------

  Future<DocumentReferencePage> listDocumentReferences({
    String? category,
    String? statusFilter,
    String? typeCode,
    String? q,
    int offset = 0,
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/document-references/',
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (statusFilter != null && statusFilter.isNotEmpty)
          'status': statusFilter,
        if (typeCode != null && typeCode.isNotEmpty) 'type_code': typeCode,
        if (q != null && q.isNotEmpty) 'q': q,
        'offset': offset,
        'limit': limit,
      },
    );
    return DocumentReferencePage.fromJson(resp.data ?? const {});
  }

  Future<DocumentReferenceDetail> getDocumentReference(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/document-references/$id/',
    );
    return DocumentReferenceDetail.fromJson(resp.data ?? const {});
  }

  // ----- ImagingStudy -------------------------------------------------------

  Future<ImagingStudyPage> listImagingStudies({
    String? modality,
    String? statusFilter,
    String? q,
    int offset = 0,
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/imaging-studies/',
      queryParameters: {
        if (modality != null && modality.isNotEmpty) 'modality': modality,
        if (statusFilter != null && statusFilter.isNotEmpty)
          'status': statusFilter,
        if (q != null && q.isNotEmpty) 'q': q,
        'offset': offset,
        'limit': limit,
      },
    );
    return ImagingStudyPage.fromJson(resp.data ?? const {});
  }

  Future<ImagingStudyDetail> getImagingStudy(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/imaging-studies/$id/',
    );
    return ImagingStudyDetail.fromJson(resp.data ?? const {});
  }

  // ----- MedicationRequest --------------------------------------------------

  Future<MedicationRequestPage> listMedicationRequests({
    String? statusFilter,     // 'active' | 'completed' | …
    bool active = false,      // shorthand for status=active
    bool past = false,        // shorthand for everything not active
    String? intent,
    String? q,
    int offset = 0,
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/medication-requests/',
      queryParameters: {
        if (statusFilter != null && statusFilter.isNotEmpty)
          'status': statusFilter,
        if (active) 'active': 'true',
        if (past) 'past': 'true',
        if (intent != null && intent.isNotEmpty) 'intent': intent,
        if (q != null && q.isNotEmpty) 'q': q,
        'offset': offset,
        'limit': limit,
      },
    );
    return MedicationRequestPage.fromJson(resp.data ?? const {});
  }

  Future<MedicationRequestDetail> getMedicationRequest(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/medication-requests/$id/',
    );
    return MedicationRequestDetail.fromJson(resp.data ?? const {});
  }

  // ----- Condition ----------------------------------------------------------

  Future<ConditionPage> listConditions({
    String? clinicalStatus,
    bool active = false,
    bool resolved = false,
    String? category,
    String? q,
    int offset = 0,
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/conditions/',
      queryParameters: {
        if (clinicalStatus != null && clinicalStatus.isNotEmpty)
          'clinical_status': clinicalStatus,
        if (active) 'active': 'true',
        if (resolved) 'resolved': 'true',
        if (category != null && category.isNotEmpty) 'category': category,
        if (q != null && q.isNotEmpty) 'q': q,
        'offset': offset,
        'limit': limit,
      },
    );
    return ConditionPage.fromJson(resp.data ?? const {});
  }

  Future<ConditionDetail> getCondition(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/clinical/conditions/$id/',
    );
    return ConditionDetail.fromJson(resp.data ?? const {});
  }
}

final clinicalApiProvider = Provider<ClinicalApi>((ref) {
  return ClinicalApi(ref.watch(dioProvider));
});
