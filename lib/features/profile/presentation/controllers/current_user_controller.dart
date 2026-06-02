// Holds the currently signed-in user's profile. Auto-fetches on login,
// clears on logout. Any screen that needs the user reads from here.

import 'dart:async';

import 'package:datasolids_mobile/core/auth/auth_state.dart';
import 'package:datasolids_mobile/features/profile/data/dtos/user_profile_dto.dart';
import 'package:datasolids_mobile/features/profile/data/profile_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrentUserState {
  const CurrentUserState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  final UserProfile? user;
  final bool isLoading;
  final String? errorMessage;

  CurrentUserState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return CurrentUserState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CurrentUserController extends StateNotifier<CurrentUserState> {
  CurrentUserController(this._ref) : super(const CurrentUserState()) {
    // Re-fetch whenever auth flips to authenticated. Clear on logout.
    _ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        // Logged in — pull profile.
        unawaited(refresh());
      } else if (!next.isAuthenticated) {
        // Logged out — drop cached user.
        state = const CurrentUserState();
      }
    }, fireImmediately: true);
  }

  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _ref.read(profileApiProvider).getMe();
      state = CurrentUserState(user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Optimistic update: replaces local cache with `next`, then if PATCH
  /// fails reverts. Returns true on success.
  Future<bool> update(Map<String, dynamic> payload) async {
    final previous = state.user;
    try {
      final updated = await _ref.read(profileApiProvider).updateMe(payload);
      state = CurrentUserState(user: updated);
      return true;
    } catch (e) {
      state = state.copyWith(
        user: previous,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Upload a new avatar from a local file path. Returns true on success.
  Future<bool> uploadAvatar(String filePath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated =
          await _ref.read(profileApiProvider).uploadAvatar(filePath);
      state = CurrentUserState(user: updated);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final currentUserControllerProvider =
    StateNotifierProvider<CurrentUserController, CurrentUserState>((ref) {
  return CurrentUserController(ref);
});
