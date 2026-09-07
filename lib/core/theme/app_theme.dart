import 'package:flutter/material.dart';

/// Identidade visual **ServiceReport** (handoff no README).
///
/// Regras de forma que valem pra tudo:
/// - **Raio 0** em cartão, campo, botão, chip, avatar, FAB, folha, diálogo.
/// - Borda 1px: `#DCDEE2` em repouso, `#12151A` em foco/preenchido.
/// - No máximo duas cores por tela: tinta + um dos azuis. Sem gradiente, sem
///   sombra na marca.
abstract final class BrandColor {
  static const ink = Color(0xFF12151A); // app bar, texto, botão, marca
  static const blue = Color(0xFF3A61C4); // acento sobre claro, links, sync
  static const blueLight = Color(0xFF618DF3); // acento sobre a tinta — nunca no branco
  static const background = Color(0xFFEDEEF0);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCDEE2);
  static const divider = Color(0xFFF0F1F3);
  static const textSecondary = Color(0xFF4C5057);
  static const textTertiary = Color(0xFF71757C);
  static const textDisabled = Color(0xFF8A8F98);
  static const errorBar = Color(0xFFA3372A);
  static const errorText = Color(0xFF7C2A20);
  static const errorBg = Color(0xFFFBEDEA);
  static const onDarkSecondary = Color(0xFFB4B9C1);
  static const onDarkTrack = Color(0xFF262A31);
  static const onDarkBorder = Color(0xFF4C5259);
}

const _sans = 'Space Grotesk';
const _mono = 'IBM Plex Mono';

/// Tokens que o `ColorScheme` do Material não cobre. Acesse por
/// `Theme.of(context).extension<BrandColors>()!` ou `context.brand`.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.blueLight,
    required this.border,
    required this.divider,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.errorBar,
    required this.errorText,
    required this.errorBg,
    required this.onDarkSecondary,
    required this.onDarkTrack,
    required this.onDarkBorder,
  });

  final Color blueLight;
  final Color border;
  final Color divider;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color errorBar;
  final Color errorText;
  final Color errorBg;
  final Color onDarkSecondary;
  final Color onDarkTrack;
  final Color onDarkBorder;

  static const _light = BrandColors(
    blueLight: BrandColor.blueLight,
    border: BrandColor.border,
    divider: BrandColor.divider,
    textSecondary: BrandColor.textSecondary,
    textTertiary: BrandColor.textTertiary,
    textDisabled: BrandColor.textDisabled,
    errorBar: BrandColor.errorBar,
    errorText: BrandColor.errorText,
    errorBg: BrandColor.errorBg,
    onDarkSecondary: BrandColor.onDarkSecondary,
    onDarkTrack: BrandColor.onDarkTrack,
    onDarkBorder: BrandColor.onDarkBorder,
  );

  @override
  BrandColors copyWith({
    Color? blueLight,
    Color? border,
    Color? divider,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? errorBar,
    Color? errorText,
    Color? errorBg,
    Color? onDarkSecondary,
    Color? onDarkTrack,
    Color? onDarkBorder,
  }) => BrandColors(
    blueLight: blueLight ?? this.blueLight,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    textDisabled: textDisabled ?? this.textDisabled,
    errorBar: errorBar ?? this.errorBar,
    errorText: errorText ?? this.errorText,
    errorBg: errorBg ?? this.errorBg,
    onDarkSecondary: onDarkSecondary ?? this.onDarkSecondary,
    onDarkTrack: onDarkTrack ?? this.onDarkTrack,
    onDarkBorder: onDarkBorder ?? this.onDarkBorder,
  );

  @override
  BrandColors lerp(BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      blueLight: Color.lerp(blueLight, other.blueLight, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      errorBar: Color.lerp(errorBar, other.errorBar, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      onDarkSecondary: Color.lerp(onDarkSecondary, other.onDarkSecondary, t)!,
      onDarkTrack: Color.lerp(onDarkTrack, other.onDarkTrack, t)!,
      onDarkBorder: Color.lerp(onDarkBorder, other.onDarkBorder, t)!,
    );
  }
}

extension BrandContext on BuildContext {
  BrandColors get brand => Theme.of(this).extension<BrandColors>()!;
}

/// Estilos de texto em **IBM Plex Mono** — marca, números, rótulos, dados,
/// códigos, datas. O resto da tipografia (Space Grotesk) sai do `textTheme`.
abstract final class BrandText {
  /// Rótulo de campo: caixa alta, espaçado. Ver `fieldLabel` no handoff.
  static const fieldLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 9.5,
    letterSpacing: 1.1, // ~0.11em
    color: BrandColor.textTertiary,
  );

  /// Valor de campo / dado (data, hora, telefone, código).
  static const fieldValue = TextStyle(
    fontFamily: _mono,
    fontSize: 13.5,
    color: BrandColor.ink,
  );

  /// Subtítulo de item de lista.
  static const listMeta = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    color: BrandColor.textTertiary,
  );

  /// Chip / badge: caixa alta, pequeno.
  static const chip = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    letterSpacing: 1.0, // 0.1em
    color: BrandColor.ink,
  );

  /// Número grande (contadores, dashboards).
  static const bigNumber = TextStyle(
    fontFamily: _mono,
    fontSize: 40,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.6, // ~-0.04em
    color: BrandColor.ink,
  );

  /// Linha "leiano" / assinatura da casa acima ou abaixo do wordmark.
  /// Valores do manual da marca (README): 11px, ~0,18em, `#4C5057`.
  static const brandOver = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    letterSpacing: 2, // ~0.18em
    color: BrandColor.textSecondary,
  );

  /// Linha "servicereport" do lockup (caixa baixa, uma palavra).
  static const brandWord = TextStyle(
    fontFamily: _mono,
    fontSize: 21,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.6,
    color: BrandColor.ink,
  );
}

/// Assinatura da casa: o ServiceReport é um produto da Leiano Sistemas.
/// Usada abaixo do wordmark na splash, no login e no cabeçalho da home.
const kBrandEndorsement = 'uma solução leiano';

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: BrandColor.ink,
      onPrimary: Colors.white,
      secondary: BrandColor.blue,
      onSecondary: Colors.white,
      surface: BrandColor.surface,
      onSurface: BrandColor.ink,
      onSurfaceVariant: BrandColor.textSecondary,
      outline: BrandColor.border,
      outlineVariant: BrandColor.divider,
      error: BrandColor.errorBar,
      onError: Colors.white,
      errorContainer: BrandColor.errorBg,
      onErrorContainer: BrandColor.errorText,
    );

    const zero = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
    OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: c, width: w),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BrandColor.background,
      fontFamily: _sans,
      splashFactory: InkSparkle.splashFactory,
      extensions: const [BrandColors._light],
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: BrandColor.ink,
            displayColor: BrandColor.ink,
            fontFamily: _sans,
          )
          .copyWith(
            headlineSmall: const TextStyle(
              fontFamily: _sans,
              fontSize: 21,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
              color: BrandColor.ink,
            ),
            titleLarge: const TextStyle(
              fontFamily: _sans,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: BrandColor.ink,
            ),
            titleMedium: const TextStyle(
              fontFamily: _sans,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: BrandColor.ink,
            ),
            bodyMedium: const TextStyle(
              fontFamily: _sans,
              fontSize: 13.5,
              height: 1.5,
              color: BrandColor.textSecondary,
            ),
            bodySmall: BrandText.listMeta,
            labelLarge: const TextStyle(
              fontFamily: _sans,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: BrandColor.ink,
            ),
            labelSmall: BrandText.fieldLabel,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BrandColor.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _sans,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BrandColor.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: BrandColor.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: BrandColor.border),
          borderRadius: BorderRadius.zero,
        ),
        margin: EdgeInsets.symmetric(vertical: 4),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColor.surface,
        border: inputBorder(BrandColor.border),
        enabledBorder: inputBorder(BrandColor.border),
        focusedBorder: inputBorder(BrandColor.ink, 1.5),
        errorBorder: inputBorder(BrandColor.errorBar),
        focusedErrorBorder: inputBorder(BrandColor.errorBar, 1.5),
        labelStyle: const TextStyle(
          fontFamily: _sans,
          color: BrandColor.textTertiary,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: _mono,
          fontSize: 12,
          letterSpacing: 0.6,
          color: BrandColor.ink,
        ),
        hintStyle: const TextStyle(color: BrandColor.textDisabled),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandColor.ink,
          foregroundColor: Colors.white,
          shape: zero,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(
            fontFamily: _sans,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: BrandColor.ink,
          foregroundColor: Colors.white,
          shape: zero,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColor.ink,
          side: const BorderSide(color: BrandColor.border),
          shape: zero,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: _sans,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandColor.blue,
          shape: zero,
          textStyle: const TextStyle(
            fontFamily: _mono,
            fontSize: 11,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: BrandColor.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: zero,
        extendedTextStyle: TextStyle(
          fontFamily: _sans,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: zero,
        side: const BorderSide(color: BrandColor.border),
        backgroundColor: BrandColor.surface,
        selectedColor: BrandColor.ink,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            fontFamily: _mono,
            fontSize: 11,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : BrandColor.ink,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: BrandColor.textTertiary,
        titleTextStyle: TextStyle(
          fontFamily: _sans,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: BrandColor.ink,
        ),
        subtitleTextStyle: BrandText.listMeta,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BrandColor.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        showDragHandle: false,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: BrandColor.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: BrandColor.ink,
        contentTextStyle: TextStyle(fontFamily: _sans, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BrandColor.blue,
        linearTrackColor: BrandColor.border,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: zero,
          selectedBackgroundColor: BrandColor.ink,
          selectedForegroundColor: Colors.white,
          side: const BorderSide(color: BrandColor.border),
        ),
      ),
    );
  }
}
