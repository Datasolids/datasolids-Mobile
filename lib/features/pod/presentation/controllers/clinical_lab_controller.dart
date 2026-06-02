// Holds a page of DiagnosticReports for the Labs list, plus a detail
// FutureProvider for the screen you land on when you tap a report.

import 'dart:async';

import 'package:datasolids_mobile/features/pod/data/clinical_api.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LabReportsState {
  const LabReportsState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.statusFilter = 'all',
    this.isLoadingFirstPage = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<DiagnosticReportSummary> items;
  final int total;
  final bool hasMore;
  /// Maps to the API status filter: 'all' (no filter) | 'final' | 'preliminary'.
  final String statusFilter;
  final bool isLoadingFirstPage;
  final bool isLoadingMore;
  final String? errorMessage;

  LabReportsState copyWith({
    List<DiagnosticReportSummary>? items,
    int? total,
    bool? hasMore,
    String? statusFilter,
    bool? isLoadingFirstPage,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LabReportsState(
      items: items ?? this.items,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LabReportsController extends StateNotifier<LabReportsState> {
  LabReportsController(this._ref) : super(const LabReportsState()) {
    unawaited(refresh());
  }

  final Ref _ref;
  static const int _pageSize = 20;

  Future<void> refresh() async {
    state = state.copyWith(isLoadingFirstPage: true, clearError: true);
    try {
      final page = await _ref.read(clinicalApiProvider).listDiagnosticReports(
            category: 'LAB',
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
      final page = await _ref.read(clinicalApiProvider).listDiagnosticReports(
            category: 'LAB',
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

final labReportsControllerProvider =
    StateNotifierProvider<LabReportsController, LabReportsState>((ref) {
  return LabReportsController(ref);
});

/// Detail screen — one-shot fetch keyed by report id.
final diagnosticReportDetailProvider =
    FutureProvider.family<DiagnosticReportDetail, String>((ref, id) {
  return ref.read(clinicalApiProvider).getDiagnosticReport(id);
});
