import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_api.dart';

/// Estado da sessão do app. [SessionUnknown] é o estado transitório enquanto
/// o app ainda está lendo o armazenamento seguro no boot — a UI deve
/// mostrar um splash/loading nesse estado, nunca a tela de login (evita um
/// flash de "deslogado" antes de restaurar uma sessão válida).
sealed class SessionState {
  const SessionState();
}

class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

class SessionAuthenticating extends SessionState {
  const SessionAuthenticating();
}

class SessionAuthenticated extends SessionState {
  const SessionAuthenticated({required this.userId, required this.organizationId});
  final String userId;
  final String organizationId;
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    ref.read(sessionExpiredPortProvider).bind(_handleSessionExpired);
    _restore();
    return const SessionUnknown();
  }

  AuthApi get _authApi => ref.read(authApiProvider);

  /// Restaura a sessão a partir do que já está no armazenamento seguro. Não
  /// valida o access token contra o servidor aqui — se estiver expirado, a
  /// primeira chamada de negócio dispara o refresh automático do
  /// [AuthInterceptor] normalmente (GUIA-FLUTTER.md §3.4).
  Future<void> _restore() async {
    final store = ref.read(secureStoreProvider);
    final accessToken = await store.readAccessToken();
    final refreshToken = await store.readRefreshToken();
    final organizationId = await store.readOrganizationId();
    final userId = await store.readUserId();

    final hasSession = accessToken != null &&
        refreshToken != null &&
        organizationId != null &&
        userId != null;

    // O provider pode ter sido descartado enquanto esperávamos o
    // armazenamento seguro (container/widget desmontado no meio do boot) —
    // sem essa checagem, `state = ...` depois do await lança.
    if (!ref.mounted) return;

    state = hasSession
        ? SessionAuthenticated(userId: userId, organizationId: organizationId)
        : const SessionUnauthenticated();
  }

  Future<void> login({required String email, required String password}) async {
    state = const SessionAuthenticating();
    final store = ref.read(secureStoreProvider);
    final deviceId = await store.getOrCreateDeviceId();

    try {
      final pair = await _authApi.login(
        email: email,
        password: password,
        deviceId: deviceId,
        deviceName: _deviceName(),
        devicePlatform: _devicePlatform(),
      );
      await store.saveSession(
        accessToken: pair.accessToken,
        refreshToken: pair.refreshToken,
        organizationId: pair.organizationId,
        userId: pair.userId,
      );
      if (!ref.mounted) return;
      state = SessionAuthenticated(userId: pair.userId, organizationId: pair.organizationId);
    } catch (_) {
      if (ref.mounted) state = const SessionUnauthenticated();
      rethrow;
    }
  }

  Future<void> logout() async {
    final store = ref.read(secureStoreProvider);
    final accessToken = await store.readAccessToken();
    if (accessToken != null) {
      await _authApi.logout(accessToken);
    }
    await store.clearSession();
    if (!ref.mounted) return;
    state = const SessionUnauthenticated();
  }

  void _handleSessionExpired() {
    unawaited(ref.read(secureStoreProvider).clearSession());
    state = const SessionUnauthenticated();
  }

  String _devicePlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String _deviceName() {
    if (kIsWeb) return 'Chrome';
    return _devicePlatform();
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
