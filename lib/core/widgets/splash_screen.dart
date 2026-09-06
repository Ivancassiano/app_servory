import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Versão exibida na splash. Espelha `version:` do pubspec (parte antes do +).
const _appVersion = '1.0.0';

/// Tela `/splash` (rota do go_router) — enquanto sessão/conectividade/trava
/// ainda não decidiram para onde ir. Fundo tinta, marca centralizada e as
/// quatro faixas pulsando em sequência (handoff §01).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // glifos brancos
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: BrandColor.ink,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulsingMark(animation: _c),
              const SizedBox(height: 20),
              Text('leiano', style: BrandText.brandOver),
              const SizedBox(height: 4),
              Text(
                'servicereport',
                style: BrandText.brandWord.copyWith(
                  fontSize: 21,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 132,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: BrandColor.blueLight,
                  backgroundColor: BrandColor.onDarkTrack,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'preparando dados do dispositivo',
                style: BrandText.listMeta.copyWith(
                  fontSize: 10.5,
                  color: BrandColor.onDarkSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'versão $_appVersion',
                style: BrandText.brandOver.copyWith(
                  letterSpacing: 0.5,
                  color: BrandColor.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// As quatro faixas da marca, cada uma com opacidade 0,22 → 1 → 0,22 num
/// ciclo de 1,6s, deslocadas 0 / 0,2 / 0,4 / 0,6s.
class _PulsingMark extends AnimatedWidget {
  const _PulsingMark({required Animation<double> animation})
    : super(listenable: animation);

  Animation<double> get _a => listenable as Animation<double>;

  static const _bars = [
    (4.0, 2.0, 14.0, 4.0),
    (4.0, 7.5, 8.0, 4.0),
    (10.0, 13.0, 8.0, 4.0),
    (4.0, 18.5, 14.0, 4.0),
  ];

  double _opacity(int i) {
    // fase deslocada por faixa, curva triangular suavizada
    final phase = (_a.value - i * 0.125) % 1.0;
    final tri = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    final eased = Curves.easeInOut.transform(tri.clamp(0.0, 1.0));
    return 0.22 + 0.78 * eased;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(80),
      painter: _MarkPainter([for (var i = 0; i < 4; i++) _opacity(i)]),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.opacities);
  final List<double> opacities;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    for (var i = 0; i < _PulsingMark._bars.length; i++) {
      final (x, y, w, h) = _PulsingMark._bars[i];
      final base = i.isEven ? Colors.white : BrandColor.blueLight;
      final paint = Paint()..color = base.withValues(alpha: opacities[i]);
      canvas.drawRect(Rect.fromLTWH(x * k, y * k, w * k, h * k), paint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.opacities != opacities;
}
