// Controllers for the Vitals / DocumentReference / ImagingStudy list +
// detail screens. Each list is a StateNotifier with filter + infinite
// scroll. Each detail is a FutureProvider.family keyed by id.

import 'dart:async';

import 'package:datasolids_mobile/features/pod/data/clinical_api.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// ============================================================================
// Vitals (Observation list scoped to category=vital-signs)
// ============================================================================


class VitalsState {
  const VitalsState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.interpretationFilter = 'all',  // 'all' | 'abnormal' | 'normal'
    this.isLoadingFirstPage = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<ObservationRow> items;
  final int total;
  final bool hasMore;
  final String interpretationFilter;
  final bool isLoadingFirstPage;
  final bool isLoadingMore;
  final String? errorMessage;

  VitalsState copyWith({
    List<ObservationRow>? items,
    int? total,
    bool? hasMore,
    String? interpretationFilter,
    bool? isLoadingFirstPage,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) => VitalsState(
        items: items ?? this.items,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        interpretationFilter:
            interpretationFilter ?? this.interpretationFilter,
        isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class VitalsController extends StateNotifier<VitalsState> {
  VitalsController(this._ref) : super(const VitalsState()) {
    unawaited(refresh());
  }
  final Ref _ref;
  static const int _pageSize = 20;

  String? get _serverInterpretation {
    // The API accepts only a literal code (N/H/HH/L/LL/A/AA); we use 'all'
    // for no filter and 'abnormal' for any non-normal — done client-side
    // because the API doesn't have a multi-value "abnormal" filter yet.
    if (state.interpretationFilter == 'normal') return 'N';
    return null;
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoadingFirstPage: true, clearError: true);
    try {
      final page = await _ref.read(clinicalApiProvider).listObservations(
            category: 'vital-signs',
            interpretation: _serverInterpretation,
            offset: 0,
            limit: _pageSize,
          );
      var items = page.results;
      if (state.interpretationFilter == 'abnormal') {
        items = items.where((r) => r.severity != 'normal').toList();
      }
      state = state.copyWith(
        items: items,
        total: page.total,
        hasMore: page.hasMore,
        isLoadingFirstPage: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFirstPage: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _ref.read(clinicalApiProvider).listObservations(
            category: 'vital-signs',
            interpretation: _serverInterpretation,
            offset: state.items.length,
            limit: _pageSize,
          );
      var newRows = page.results;
      if (state.interpretationFilter == 'abnormal') {
        newRows = newRows.where((r) => r.severity != 'normal').toList();
      }
      state = state.copyWith(
        items: [...state.items, ...newRows],
        total: page.total,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setInterpretationFilter(String f) async {
    if (f == state.interpretationFilter) return;
    state = state.copyWith(
      interpretationFilter: f, items: const [], total: 0,
    );
    await refresh();
  }
}

final vitalsControllerProvider =
    StateNotifierProvider<VitalsController, VitalsState>((ref) {
  return VitalsController(ref);
});

final observationDetailProvider =
    FutureProvider.family<ObservationDetail, String>((ref, id) {
  return ref.read(clinicalApiProvider).getObservation(id);
});


// ============================================================================
// DocumentReference
// ============================================================================


class DocumentReferencesState {
  const DocumentReferencesState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.statusFilter = 'all',  // 'all' | 'current' | 'superseded'
    this.isLoadingFirstPage = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<DocumentReferenceSummary> items;
  final int total;
  final bool hasMore;
  final String statusFilter;
  final bool isLoadingFirstPage;
  final bool isLoadingMore;
  final String? errorMessage;

  DocumentReferencesState copyWith({
    List<DocumentReferenceSummary>? items,
    int? total,
    bool? hasMore,
    String? statusFilter,
    bool? isLoadingFirstPage,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) => DocumentReferencesState(
        items: items ?? this.items,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        statusFilter: statusFilter ?? this.statusFilter,
        isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class DocumentReferencesController
    extends StateNotifier<DocumentReferencesState> {
  DocumentReferencesController(this._ref)
      : super(const DocumentReferencesState()) {
    unawaited(refresh());
  }
  final Ref _ref;
  static const int _pageSize = 20;

  Future<void> refresh() async {
    state = state.copyWith(isLoadingFirstPage: true, clearError: true);
    try {
      final page =
          await _ref.read(clinicalApiProvider).listDocumentReferences(
                statusFilter:
                    state.statusFilter == 'all' ? null : state.statusFilter,
                offset: 0,
                limit: _pageSize,
              );
      state = state.copyWith(
        items: page.results,
        total: page.total,
        hasMore: page.hasMore,
        isLoadingFirstPage: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFirstPage: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page =
          await _ref.read(clinicalApiProvider).listDocumentReferences(
                statusFilter:
                    state.statusFilter == 'all' ? null : state.statusFilter,
                offset: state.items.length,
                limit: _pageSize,
              );
      state = state.copyWith(
        items: [...state.items, ...page.results],
        total: page.total,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setStatusFilter(String f) async {
    if (f == state.statusFilter) return;
    state = state.copyWith(statusFilter: f, items: const [], total: 0);
    await refresh();
  }
}

final documentReferencesControllerProvider = StateNotifierProvider<
    DocumentReferencesController, DocumentReferencesState>((ref) {
  return DocumentReferencesController(ref);
});

final documentReferenceDetailProvider =
    FutureProvider.family<DocumentReferenceDetail, String>((ref, id) {
  return ref.read(clinicalApiProvider).getDocumentReference(id);
});


// ============================================================================
// ImagingStudy
// ============================================================================


class ImagingStudiesState {
  const ImagingStudiesState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.modalityFilter = 'all',
    this.isLoadingFirstPage = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<ImagingStudySummary> items;
  final int total;
  final bool hasMore;
  final String modalityFilter;
  final bool isLoadingFirstPage;
  final bool isLoadingMore;
  final String? errorMessage;

  ImagingStudiesState copyWith({
    List<ImagingStudySummary>? items,
    int? total,
    bool? hasMore,
    String? modalityFilter,
    bool? isLoadingFirstPage,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) => ImagingStudiesState(
        items: items ?? this.items,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        modalityFilter: modalityFilter ?? this.modalityFilter,
        isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class ImagingStudiesController
    extends StateNotifier<ImagingStudiesState> {
  ImagingStudiesController(this._ref)
      : super(const ImagingStudiesState()) {
    unawaited(refresh());
  }
  final Ref _ref;
  static const int _pageSize = 20;

  Future<void> refresh() async {
    state = state.copyWith(isLoadingFirstPage: true, clearError: true);
    try {
      final page = await _ref.read(clinicalApiProvider).listImagingStudies(
            modality:
                state.modalityFilter == 'all' ? null : state.modalityFilter,
            offset: 0,
            limit: _pageSize,
          );
      state = state.copyWith(
        items: page.results,
        total: page.total,
        hasMore: page.hasMore,
        isLoadingFirstPage: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFirstPage: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _ref.read(clinicalApiProvider).listImagingStudies(
            modality:
                state.modalityFilter == 'all' ? null : state.modalityFilter,
            offset: state.items.length,
            limit: _pageSize,
          );
      state = state.copyWith(
        items: [...state.items, ...page.results],
        total: page.total,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setModalityFilter(String m) async {
    if (m == state.modalityFilter) return;
    state = state.copyWith(modalityFilter: m, items: const [], total: 0);
    await refresh();
  }
}

final imagingStudiesControllerProvider = StateNotifierProvider<
    ImagingStudiesController, ImagingStudiesState>((ref) {
  return ImagingStudiesController(ref);
});

final imagingStudyDetailProvider =
    FutureProvider.family<ImagingStudyDetail, String>((ref, id) {
  return ref.read(clinicalApiProvider).getImagingStudy(id);
});


// ============================================================================
// DiagnosticReport — general (all categories) list
// Used by the "Diagnostic Reports" tile (vs the Labs tile which filters
// to category=LAB).
// ============================================================================


class AllDiagnosticReportsState {
  const AllDiagnosticReportsState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.categoryFilter = 'all',  // 'all' | 'LAB' | 'RAD' | 'PAT' | ...
    this.isLoadingFirstPage = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<DiagnosticReportSummary> items;
  final int total;
  final bool hasMore;
  final String categoryFilter;
  final bool isLoadingFirstPage;
  final bool isLoadingMore;
  final String? errorMessage;

  AllDiagnosticReportsState copyWith({
    List<DiagnosticReportSummary>? items,
    int? total,
    bool? hasMore,
    String? categoryFilter,
    bool? isLoadingFirstPage,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) => AllDiagnosticReportsState(
        items: items ?? this.items,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        categoryFilter: categoryFilter ?? this.categoryFilter,
        isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class AllDiagnosticReportsController
    extends StateNotifier<AllDiagnosticReportsState> {
  AllDiagnosticReportsController(this._ref)
      : super(const AllDiagnosticReportsState()) {
    unawaited(refresh());
  }
  final Ref _ref;
  static const int _pageSize = 20;

  Future<void> refresh() async {
    state = state.copyWith(isLoadingFirstPage: true, clearError: true);
    try {
      final page = await _ref.read(clinicalApiProvider).listDiagnosticReports(
            category:
                state.categoryFilter == 'all' ? null : state.categoryFilter,
            offset: 0,
            limit: _pageSize,
          );
      state = state.copyWith(
        items: page.results,
        total: page.total,
        hasMore: page.hasMore,
        isLoadingFirstPage: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFirstPage: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _ref.read(clinicalApiProvider).listDiagnosticReports(
            category:
                state.categoryFilter == 'all' ? null : state.categoryFilter,
            offset: state.items.length,
            limit: _pageSize,
          );
      state = state.copyWith(
        items: [...state.items, ...page.results],
        total: page.total,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setCategoryFilter(String c) async {
    if (c == state.categoryFilter) return;
    state = state.copyWith(categoryFilter: c, items: const [], total: 0);
    await refresh();
  }
}

final allDiagnosticReportsControllerProvider = StateNotifierProvider<
    AllDiagnosticReportsController, AllDiagnosticReportsState>((ref) {
  return AllDiagnosticReportsController(ref);
});
