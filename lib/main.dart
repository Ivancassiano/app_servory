import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/application/session_controller.dart';

void main() {
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
}
