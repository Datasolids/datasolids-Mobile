// Controllers for the Security home + sessions + activity log.
// Detail screens (MFA setup, recovery codes) hold their own ephemeral
// state — they don't need a global notifier.

import 'dart:async';

import 'package:datasolids_mobile/features/security/data/dtos/security.dart';
import 'package:datasolids_mobile/features/security/data/security_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class SecurityHomeState {
  const SecurityHomeState({
    this.home,
    this.isLoading = false,
    this.errorMessage,
  });

  final SecurityHome? home;
  final bool isLoading;
  final String? errorMessage;

  SecurityHomeState copyWith({
    SecurityHome? home,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) => SecurityHomeState(
        home: home ?? this.home,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class SecurityHomeController extends StateNotifier<SecurityHomeState> {
  SecurityHomeController(this._ref) : super(const SecurityHomeState()) {
    unawaited(refresh());
  }
  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final home = await _ref.read(securityApiProvider).getHome();
      state = SecurityHomeState(home: home);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final securityHomeControllerProvider =
    StateNotifierProvider<SecurityHomeController, SecurityHomeState>((ref) {
  return SecurityHomeController(ref);
});

// One-shot list providers — they auto-refresh when invalidated.
final activeSessionsProvider =
    FutureProvider<List<LoginSessionItem>>((ref) {
  return ref.read(securityApiProvider).listSessions();
});

final securityEventsProvider =
    FutureProvider<List<SecurityEventItem>>((ref) {
  return ref.read(securityApiProvider).listEvents();
});
