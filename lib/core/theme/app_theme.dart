import 'package:flutter/material.dart';

/// Tema Material 3 básico. Paleta e tipografia definitivas ficam para quando
/// o produto tiver uma identidade visual — por ora, só o necessário para não
/// rodar com o tema default do framework.
class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6F4F)),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}
