// Holds the Home dashboard summary (pod status, sources, activity).
// Auto-fetches on login, clears on logout. The Home screen reads from here
// to decide between the empty/first-time state and the populated state.

import 'dart:async';

import 'package:datasolids_mobile/core/auth/auth_state.dart';
import 'package:datasolids_mobile/features/home/data/dashboard_api.dart';
import 'package:datasolids_mobile/features/home/data/dtos/dashboard_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardState {
  const DashboardState({
    this.summary,
    this.isLoading = false,
    this.errorMessage,
  });

  final DashboardSummary? summary;
  final bool isLoading;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardSummary? summary,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._ref) : super(const DashboardState()) {
    _ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        unawaited(refresh());
      } else if (!next.isAuthenticated) {
        state = const DashboardState();
      }
    }, fireImmediately: true);
  }

  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final summary = await _ref.read(dashboardApiProvider).getSummary();
      state = DashboardState(summary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  return DashboardController(ref);
});
