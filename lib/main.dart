import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/application/session_controller.dart';

void main() {
  // Handlers globais: um erro solto (ex.: leitura do armazenamento seguro
  // falhando num update do Android) não pode deixar o app preso no splash
  // em silêncio — registra e segue.
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('flutter error (não fatal): ${details.exceptionAsString()}');
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('erro assíncrono não tratado: $error');
        return true;
      };
      runApp(
        ProviderScope(
          overrides: [
            // Segura o splash por pelo menos 3s no boot, mesmo quando a sessão
            // restaura na hora — dá ao usuário a sensação de que o app carregou.
            bootSplashMinDurationProvider.overrideWithValue(
              const Duration(seconds: 3),
            ),
          ],
          child: const ServoryApp(),
        ),
      );
    },
    (error, stack) => debugPrint('erro fora da zona do Flutter: $error'),
  );
}
