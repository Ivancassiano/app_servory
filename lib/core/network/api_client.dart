import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_store.dart';
import 'auth_interceptor.dart';

/// Os dois hosts do backend (GUIA-FLUTTER.md §2): [authDio] fala com o
/// `auth-api` (login/refresh/sessões — nunca leva o interceptor de token,
/// já que essas chamadas não exigem sessão prévia) e [businessDio] fala com
/// o `servicelog-api` (tudo mais), sempre autenticado.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required SecureStore store,
    void Function()? onSessionExpired,
  }) : authDio = Dio(
         BaseOptions(
           baseUrl: config.authBaseUrl,
           connectTimeout: const Duration(seconds: 15),
         ),
       ),
       businessDio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: const Duration(seconds: 15),
         ),
       ) {
    businessDio.interceptors.add(
      AuthInterceptor(
        authDio: authDio,
        businessDio: businessDio,
        store: store,
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  final Dio authDio;
  final Dio businessDio;
}
