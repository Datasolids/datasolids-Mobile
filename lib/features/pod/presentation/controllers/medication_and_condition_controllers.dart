// Controllers for the typed Medications and Conditions screens.
// Pattern matches the other clinical_*_controllers files: StateNotifier
// with filter + infinite scroll for lists, FutureProvider.family for details.

import 'dart:async';

import 'package:datasolids_mobile/features/pod/data/clinical_api.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/clinical.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// ============================================================================
// MedicationRequest
// ============================================================================


class MedicationsState {
  const MedicationsState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.filter = 'all',          // 'all' | 'active' | 'past'
    this.isLoadingFirstPage = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<MedicationRequestSummary> items;
  final int total;
  final bool hasMore;
  final String filter;
  final bool isLoadingFirstPage;
  final bool isLoadingMore;
  final String? errorMessage;

  MedicationsState copyWith({
    List<MedicationRequestSummary>? items,
    int? total,
    bool? hasMore,
    String? filter,
    bool? isLoadingFirstPage,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) => MedicationsState(
        items: items ?? this.items,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        filter: filter ?? this.filter,
        isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class MedicationsController extends StateNotifier<MedicationsState> {
  MedicationsController(this._ref) : super(const MedicationsState()) {
    unawaited(refresh());
  }
  final Ref _ref;
  static const int _pageSize = 20;

  Future<void> refresh() async {
    state = state.copyWith(isLoadingFirstPage: true, clearError: true);
    try {
      final page = await _ref.read(clinicalApiProvider).listMedicationRequests(
            active: state.filter == 'active',
            past: state.filter == 'past',
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
      final page = await _ref.read(clinicalApiProvider).listMedicationRequests(
            active: state.filter == 'active',
            past: state.filter == 'past',
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

  Future<void> setFilter(String f) async {
    if (f == state.filter) return;
    state = state.copyWith(filter: f, items: const [], total: 0);
    await refresh();
  }
}

final medicationsControllerProvider =
    StateNotifierProvider<MedicationsController, MedicationsState>((ref) {
  return MedicationsController(ref);
});

final medicationDetailProvider =
    FutureProvider.family<MedicationRequestDetail, String>((ref, id) {
  return ref.read(clinicalApiProvider).getMedicationRequest(id);
});


// ============================================================================
// Condition
// ============================================================================


class ConditionsState {
  const ConditionsState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.filter = 'all',          // 'all' | 'active' | 'resolved'
    this.isLoadingFirstPage = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<ConditionSummary> items;
  final int total;
  final bool hasMore;
  final String filter;
  final bool isLoadingFirstPage;
  final bool isLoadingMore;
  final String? errorMessage;

  ConditionsState copyWith({
    List<ConditionSummary>? items,
    int? total,
    bool? hasMore,
    String? filter,
    bool? isLoadingFirstPage,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) => ConditionsState(
        items: items ?? this.items,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        filter: filter ?? this.filter,
        isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class ConditionsController extends StateNotifier<ConditionsState> {
  ConditionsController(this._ref) : super(const ConditionsState()) {
    unawaited(refresh());
  }
  final Ref _ref;
  static const int _pageSize = 20;

  Future<void> refresh() async {
    state = state.copyWith(isLoadingFirstPage: true, clearError: true);
    try {
      final page = await _ref.read(clinicalApiProvider).listConditions(
            active: state.filter == 'active',
            resolved: state.filter == 'resolved',
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
      final page = await _ref.read(clinicalApiProvider).listConditions(
            active: state.filter == 'active',
            resolved: state.filter == 'resolved',
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

  Future<void> setFilter(String f) async {
    if (f == state.filter) return;
    state = state.copyWith(filter: f, items: const [], total: 0);
    await refresh();
  }
}

final conditionsControllerProvider =
    StateNotifierProvider<ConditionsController, ConditionsState>((ref) {
  return ConditionsController(ref);
});

final conditionDetailProvider =
    FutureProvider.family<ConditionDetail, String>((ref, id) {
  return ref.read(clinicalApiProvider).getCondition(id);
});
