// Loads + caches the My Pod Explorer payload. Same shape as DashboardController:
// auto-fetches on login, clears on logout, exposes a `refresh()` for pull-to-refresh
// and a manual reload after a successful sync.

import 'dart:async';

import 'package:datasolids_mobile/core/auth/auth_state.dart';
import 'package:datasolids_mobile/features/pod/data/dtos/pod_categories.dart';
import 'package:datasolids_mobile/features/pod/data/pod_categories_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PodCategoriesState {
  const PodCategoriesState({
    this.summary,
    this.isLoading = false,
    this.errorMessage,
  });

  final PodCategoriesSummary? summary;
  final bool isLoading;
  final String? errorMessage;

  PodCategoriesState copyWith({
    PodCategoriesSummary? summary,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PodCategoriesState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PodCategoriesController extends StateNotifier<PodCategoriesState> {
  PodCategoriesController(this._ref) : super(const PodCategoriesState()) {
    _ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        unawaited(refresh());
      } else if (!next.isAuthenticated) {
        state = const PodCategoriesState();
      }
    }, fireImmediately: true);
  }

  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final summary =
          await _ref.read(podCategoriesApiProvider).getCategories();
      state = PodCategoriesState(summary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final podCategoriesControllerProvider =
    StateNotifierProvider<PodCategoriesController, PodCategoriesState>((ref) {
  return PodCategoriesController(ref);
});
