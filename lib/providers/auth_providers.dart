import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../config/api_config.dart';
import '../models/auth_models.dart';
import '../network/auth_api.dart';
import '../repositories/auth_repository.dart';
import '../repositories/session_store.dart';
import 'vehicle_providers.dart';

/// The opened `hive_ce` box holding the session. Overridden in `main()` once
/// Hive has been initialised.
final sessionBoxProvider = Provider<Box<dynamic>>((ref) {
  throw StateError(
    'sessionBoxProvider must be overridden with an opened Hive box in main().',
  );
});

final sessionStoreProvider = Provider<SessionStore>((ref) {
  final store = SessionStore(ref.watch(sessionBoxProvider));
  ref.onDispose(store.dispose);
  return store;
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authApiProvider), ref.watch(dioProvider));
});

enum AuthStatus {
  /// A stored token is being validated against `/auth/me`.
  checking,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.sessionExpired = false,
  });

  final AuthStatus status;
  final AuthUser? user;

  /// `true` when the user was signed out by an expired/rejected token rather
  /// than by pressing logout, so the login screen can explain why.
  final bool sessionExpired;
}

/// Owns the session: restores it on start-up, validates it, and drops it when
/// the server rejects the token.
class AuthNotifier extends Notifier<AuthState> {
  /// Set while [logout] clears the store, so the store listener does not
  /// mistake a deliberate sign-out for an expired session.
  bool _clearingForLogout = false;

  @override
  AuthState build() {
    final store = ref.watch(sessionStoreProvider);
    store.addListener(_onSessionChanged);
    ref.onDispose(() => store.removeListener(_onSessionChanged));

    if (store.token == null) {
      // Nothing stored, or the stored token is already past its expiry.
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    Future.microtask(_validateStoredSession);
    return AuthState(status: AuthStatus.checking, user: store.user);
  }

  /// Confirms a restored token is still good. The Dio interceptor clears the
  /// session on a 401, so this only has to reflect that in the state.
  Future<void> _validateStoredSession() async {
    final store = ref.read(sessionStoreProvider);
    try {
      final user = await ref.read(authRepositoryProvider).me();
      // Admit the user first; refreshing the cached copy is a write-behind and
      // must not hold the UI on disk I/O.
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await store.updateUser(user);
    } on AuthApiException catch (e) {
      if (e.isUnauthorized) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          sessionExpired: true,
        );
      } else {
        // A network failure is not a rejected token — keep the restored
        // session so a flaky connection does not sign the user out.
        state = AuthState(status: AuthStatus.authenticated, user: store.user);
      }
    } catch (_) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: store.user,
      );
    }
  }

  /// Reacts to the session being cleared elsewhere — in practice the Dio error
  /// interceptor after a 401 on a protected endpoint.
  void _onSessionChanged() {
    if (_clearingForLogout) return;
    final store = ref.read(sessionStoreProvider);
    if (store.token == null && state.status != AuthStatus.unauthenticated) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        sessionExpired: true,
      );
    }
  }

  void onLoginSuccess(AuthUser user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    _clearingForLogout = true;
    try {
      await ref.read(sessionStoreProvider).clear();
    } finally {
      _clearingForLogout = false;
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class LoginFormState {
  const LoginFormState({
    this.isSubmitting = false,
    this.isSlow = false,
    this.generalError,
    this.fieldErrors = const {},
  });

  final bool isSubmitting;

  /// Set once a submit has been running long enough that the delay needs
  /// explaining - a spun-down free-tier backend can take about a minute.
  final bool isSlow;
  final String? generalError;
  final Map<String, String> fieldErrors;
}

class LoginFormNotifier extends Notifier<LoginFormState> {
  @override
  LoginFormState build() => const LoginFormState();

  /// Clears the server-side error for a single field once the user edits it.
  void clearFieldError(String field) {
    if (!state.fieldErrors.containsKey(field)) return;
    final remaining = Map<String, String>.of(state.fieldErrors)..remove(field);
    state = LoginFormState(
      isSubmitting: state.isSubmitting,
      generalError: state.generalError,
      fieldErrors: remaining,
    );
  }

  void clearErrors() {
    state = const LoginFormState();
  }

  /// Signs in and persists the session. Returns `true` on success.
  Future<bool> submit({
    required String username,
    required String password,
  }) async {
    state = const LoginFormState(isSubmitting: true);

    // Flips the UI to "still working" rather than leaving a bare spinner.
    final slowTimer = Timer(ApiConfig.slowRequestHint, () {
      if (state.isSubmitting) {
        state = const LoginFormState(isSubmitting: true, isSlow: true);
      }
    });

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);

      await ref.read(sessionStoreProvider).save(
        token: result.token,
        user: result.user,
        expiresInSeconds: result.expiresIn,
      );
      ref.read(authProvider.notifier).onLoginSuccess(result.user);

      state = const LoginFormState(isSubmitting: false);
      return true;
    } on AuthApiException catch (e) {
      state = LoginFormState(
        isSubmitting: false,
        generalError: e.message,
        fieldErrors: e.fieldErrors ?? const {},
      );
      return false;
    } catch (_) {
      state = const LoginFormState(
        isSubmitting: false,
        generalError: 'An unexpected error occurred while signing in.',
      );
      return false;
    } finally {
      slowTimer.cancel();
    }
  }
}

final loginFormProvider =
    NotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>(
      LoginFormNotifier.new,
    );
