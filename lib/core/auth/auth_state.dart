import 'package:datasolids_mobile/core/auth/token_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tri-state auth so the router can distinguish "we haven't checked
/// the keychain yet" from "checked → no valid session". The splash
/// stays mounted as long as state is [unknown]; once warmFromStorage
/// flips it to [authenticated] / [unauthenticated] the redirect picks
/// the right destination.
class AuthState {
  const AuthState._(this._kind);
  final _Kind _kind;

  bool get isAuthenticated => _kind == _Kind.authenticated;
  bool get isWarming => _kind == _Kind.unknown;

  static const unknown = AuthState._(_Kind.unknown);
  static const authenticated = AuthState._(_Kind.authenticated);
  static const unauthenticated = AuthState._(_Kind.unauthenticated);
}

enum _Kind { unknown, authenticated, unauthenticated }

final authStateProvider = StateProvider<AuthState>((ref) {
  // Starts as unknown — the splash kicks off `warmFromStorage` which
  // flips this to authenticated / unauthenticated. The router holds
  // the user on the splash while we're in this state.
  return AuthState.unknown;
});

/// `Listenable` adapter so `GoRouter.refreshListenable` can rebuild
/// when auth state flips.
final authStateChangesProvider = Provider<ChangeNotifier>((ref) {
  final notifier = _AuthChangeNotifier();
  ref.listen<AuthState>(
    authStateProvider,
    (_, __) => notifier.notifyChange(),
  );
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _AuthChangeNotifier extends ChangeNotifier {
  void notifyChange() => notifyListeners();
}

/// Side-channel for the TokenManager to flip auth state without
/// exposing the StateProvider directly to feature code.
extension AuthStateRefX on Ref {
  void setAuthenticated({required bool value}) {
    read(authStateProvider.notifier).state =
        value ? AuthState.authenticated : AuthState.unauthenticated;
  }
}

/// Convenience for views.
extension AuthStateWidgetX on WidgetRef {
  bool get isAuthenticated => watch(authStateProvider).isAuthenticated;
  Future<void> signOut() => read(tokenManagerProvider).signOut();
}
