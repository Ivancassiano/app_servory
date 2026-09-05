import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Endereços base dos dois hosts do backend (GUIA-FLUTTER.md §2):
/// `auth-api` (login/refresh/sessões) e `servicelog-api` (tudo mais).
///
/// Em dev, cada plataforma enxerga "localhost" de um jeito diferente:
/// - Chrome e iOS simulator: `localhost` funciona (mesma rede do host).
/// - Emulador Android: `localhost` é o próprio emulador; o host vira
///   `10.0.2.2`.
/// - Dispositivo físico ou build de produção: sempre via `--dart-define`.
class AppConfig {
  const AppConfig({required this.authBaseUrl, required this.apiBaseUrl});

  final String authBaseUrl;
  final String apiBaseUrl;

  static AppConfig resolve() {
    const authOverride = String.fromEnvironment('AUTH_BASE_URL');
    const apiOverride = String.fromEnvironment('API_BASE_URL');
    if (authOverride.isNotEmpty && apiOverride.isNotEmpty) {
      return const AppConfig(
        authBaseUrl: authOverride,
        apiBaseUrl: apiOverride,
      );
    }

    final devHost = _devHost();
    return AppConfig(
      authBaseUrl: authOverride.isNotEmpty
          ? authOverride
          : 'http://$devHost:8080',
      apiBaseUrl: apiOverride.isNotEmpty
          ? apiOverride
          : 'http://$devHost:8081',
    );
  }

  static String _devHost() {
    if (kIsWeb) return 'localhost';
    if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
    return 'localhost';
  }
}
