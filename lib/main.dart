import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

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
      runApp(const ProviderScope(child: ServoryApp()));
    },
    (error, stack) => debugPrint('erro fora da zona do Flutter: $error'),
  );
}
