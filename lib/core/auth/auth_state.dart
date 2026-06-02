import 'package:datasolids_mobile/core/auth/token_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trivial wrapper over the token manager so the router can read
/// authentication state synchronously after the first frame.
class AuthState {
  const AuthState({required this.isAuthenticated});
  final bool isAuthenticated;

  static const unknown = AuthState(isAuthenticated: false);
}

final authStateProvider = StateProvider<AuthState>((ref) {
  // The TokenManager warms this on bootstrap; until then the router
  // shows the splash screen.
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
        AuthState(isAuthenticated: value);
  }
}

/// Convenience for views.
extension AuthStateWidgetX on WidgetRef {
  bool get isAuthenticated => watch(authStateProvider).isAuthenticated;
  Future<void> signOut() => read(tokenManagerProvider).signOut();
}
