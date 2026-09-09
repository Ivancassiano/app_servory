import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/secure_store.dart';
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
  const SessionAuthenticated({
    required this.userId,
    required this.organizationId,
  });
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
    // Tempo mínimo de splash no boot: mesmo quando a restauração resolve na
    // hora, o usuário vê o app "carregando" por um instante em vez de um
    // flash. Roda em paralelo com a leitura do armazenamento seguro.
    final minSplashDuration = ref.read(bootSplashMinDurationProvider);
    final minSplash = minSplashDuration <= Duration.zero
        ? Future<void>.value()
        : Future<void>.delayed(minSplashDuration);

    final store = ref.read(secureStoreProvider);
    // Uma falha ao ler o armazenamento seguro (chave do Keystore rotacionada,
    // dados corrompidos por um update) não pode travar o boot no splash —
    // trata como "sem sessão" e cai na tela de login.
    var hasSession = false;
    String? organizationId;
    String? userId;
    try {
      final accessToken = await store.readAccessToken();
      final refreshToken = await store.readRefreshToken();
      organizationId = await store.readOrganizationId();
      userId = await store.readUserId();
      hasSession =
          accessToken != null &&
          refreshToken != null &&
          organizationId != null &&
          userId != null;
    } catch (_) {
      hasSession = false;
    }

    await minSplash;

    // O provider pode ter sido descartado enquanto esperávamos o
    // armazenamento seguro (container/widget desmontado no meio do boot) —
    // sem essa checagem, `state = ...` depois do await lança.
    if (!ref.mounted) return;
    // `_restore` só resolve o SessionUnknown inicial; se um login/logout já
    // moveu o estado enquanto líamos o armazenamento, respeita esse.
    if (state is! SessionUnknown) return;

    state = hasSession
        ? SessionAuthenticated(userId: userId!, organizationId: organizationId!)
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
      await _activate(store, pair);
      // A tela de login sempre volta pré-preenchida com o último e-mail.
      await store.saveLastEmail(email);
      // Com "entrar com digital" ligado, guarda as credenciais para relogar
      // por biometria quando a sessão do servidor expirar.
      if (await store.readBiometricLoginEnabled()) {
        await store.saveCredentials(email: email, password: password);
      }
    } catch (_) {
      if (ref.mounted) state = const SessionUnauthenticated();
      rethrow;
    }
  }

  /// Relogin por biometria: pede a digital/PIN e, se confirmado, usa as
  /// credenciais salvas para logar de novo. Devolve `false` se a biometria
  /// falhar/for cancelada ou não houver credenciais.
  Future<bool> loginWithBiometrics() async {
    final store = ref.read(secureStoreProvider);
    final creds = await store.readCredentials();
    if (creds == null) return false;
    final ok = await ref
        .read(biometricGateProvider)
        .authenticate('Entre no ServiceReport com sua digital');
    if (!ok) return false;
    await login(email: creds.email, password: creds.password);
    return true;
  }

  Future<bool> isBiometricLoginEnabled() =>
      ref.read(secureStoreProvider).readBiometricLoginEnabled();

  /// Liga o "entrar com digital": confirma a senha com o servidor e guarda as
  /// credenciais. Não passa pelo estado `SessionAuthenticating` (o usuário já
  /// está logado, na tela de Configurações). Lança se a senha estiver errada.
  Future<void> enableBiometricLogin({
    required String email,
    required String password,
  }) async {
    final store = ref.read(secureStoreProvider);
    final deviceId = await store.getOrCreateDeviceId();
    final pair = await _authApi.login(
      email: email,
      password: password,
      deviceId: deviceId,
      deviceName: _deviceName(),
      devicePlatform: _devicePlatform(),
    );
    await store.setBiometricLoginEnabled(true);
    await store.saveCredentials(email: email, password: password);
    await store.saveLastEmail(email);
    await _activate(store, pair);
  }

  Future<void> disableBiometricLogin() =>
      ref.read(secureStoreProvider).forgetBiometricLogin();

  /// Auto-cadastro. Não muda o estado da sessão — o usuário continua
  /// deslogado e vai para a tela de confirmação de e-mail; o login só passa a
  /// funcionar depois do [verifyEmail].
  Future<void> register({
    required String organizationName,
    required String name,
    required String email,
    required String password,
  }) {
    return _authApi.register(
      organizationName: organizationName,
      name: name,
      email: email,
      password: password,
    );
  }

  /// Confirma o e-mail pelo código e já entra (o backend devolve o par de
  /// tokens). Mesma ativação do [login].
  Future<void> verifyEmail({required String code}) async {
    state = const SessionAuthenticating();
    final store = ref.read(secureStoreProvider);
    final deviceId = await store.getOrCreateDeviceId();
    try {
      final pair = await _authApi.verifyEmail(
        token: code,
        deviceId: deviceId,
        deviceName: _deviceName(),
        devicePlatform: _devicePlatform(),
      );
      await _activate(store, pair);
    } catch (_) {
      if (ref.mounted) state = const SessionUnauthenticated();
      rethrow;
    }
  }

  Future<void> resendVerification(String email) =>
      _authApi.resendVerification(email: email);

  /// Aceita um convite pelo código e entra direto (mesma ativação do login).
  Future<void> acceptInvite({
    required String code,
    required String name,
    required String password,
  }) async {
    state = const SessionAuthenticating();
    final store = ref.read(secureStoreProvider);
    final deviceId = await store.getOrCreateDeviceId();
    try {
      final pair = await _authApi.acceptInvitation(
        token: code,
        name: name,
        password: password,
        deviceId: deviceId,
        deviceName: _deviceName(),
        devicePlatform: _devicePlatform(),
      );
      await _activate(store, pair);
    } catch (_) {
      if (ref.mounted) state = const SessionUnauthenticated();
      rethrow;
    }
  }

  Future<void> _activate(SecureStore store, TokenPair pair) async {
    await store.saveSession(
      accessToken: pair.accessToken,
      refreshToken: pair.refreshToken,
      organizationId: pair.organizationId,
      userId: pair.userId,
    );
    await store.saveLastOnlineValidation(DateTime.now());
    if (!ref.mounted) return;
    state = SessionAuthenticated(
      userId: pair.userId,
      organizationId: pair.organizationId,
    );
  }

  /// Consumido uma vez pela tela de login: logo após um "Sair" explícito ela
  /// não dispara o auto-prompt da digital (senão o usuário "sai" e volta na
  /// hora). Numa expiração de sessão o prompt continua abrindo sozinho.
  bool _skipBiometricPromptOnce = false;

  bool consumeSkipBiometricPrompt() {
    final skip = _skipBiometricPromptOnce;
    _skipBiometricPromptOnce = false;
    return skip;
  }

  Future<void> logout() async {
    final store = ref.read(secureStoreProvider);
    final accessToken = await store.readAccessToken();
    if (accessToken != null) {
      await _authApi.logout(accessToken);
    }
    // "Sair" limpa a sessão, mas mantém o e-mail e o "entrar com digital" —
    // a tela de login volta pré-preenchida e com o botão da digital. Só o
    // toggle nas Configurações esquece as credenciais de vez.
    await store.clearSession();
    _skipBiometricPromptOnce = true;
    if (!ref.mounted) return;
    state = const SessionUnauthenticated();
  }

  /// Sessão do servidor expirou (refresh falhou/revogado). Limpa os tokens mas
  /// mantém e-mail/senha salvos — a tela de login vem pré-preenchida e com o
  /// "entrar com digital" (spec §16.4).
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

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Tempo mínimo que o splash fica visível no boot (ver [SessionController._restore]).
/// O padrão é zero (nenhum atraso) — quem liga isso é o `main.dart`, que
/// sobrescreve com 3s no app de verdade. Assim os testes de widget não ganham
/// um timer pendente só por encostarem na sessão.
final bootSplashMinDurationProvider = Provider<Duration>(
  (_) => Duration.zero,
);

/// Organização ativa — conveniência para repositórios/mapeadores que
/// precisam do `organization_id` (o backend não o devolve em todo payload
/// REST). Lança se lido sem sessão autenticada, igual a `appDatabaseProvider`.
final organizationIdProvider = Provider<String>((ref) {
  final session = ref.watch(sessionControllerProvider);
  if (session is SessionAuthenticated) return session.organizationId;
  throw StateError('organizationIdProvider lido sem sessão autenticada');
});
