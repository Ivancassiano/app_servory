import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ícone da marca ServiceReport: quatro faixas retas numa grade 24×24
/// formando um S em zigue-zague (coordenadas exatas no handoff do README).
///
/// - [onDark]: sobre o bloco `#12151A` — faixas 1/3 brancas, 2/4 azul-claro.
///   Sobre claro — faixas 1/3 tinta, 2/4 azul.
/// - [mono]: abaixo de ~20px, todas as faixas numa cor só (o vão fecha e o
///   azul suja o desenho).
class BrandIcon extends StatelessWidget {
  const BrandIcon({super.key, this.size = 24, this.onDark = false, this.mono});

  final double size;
  final bool onDark;

  /// Força monocromático. Se nulo, decide por [size] (< 20 = mono).
  final bool? mono;

  @override
  Widget build(BuildContext context) {
    final isMono = mono ?? size < 20;
    final Color a = onDark ? Colors.white : BrandColor.ink;
    final Color b = isMono
        ? a
        : (onDark ? BrandColor.blueLight : BrandColor.blue);
    return CustomPaint(
      size: Size.square(size),
      painter: _BrandIconPainter(a, b),
    );
  }
}

class _BrandIconPainter extends CustomPainter {
  const _BrandIconPainter(this.a, this.b);
  final Color a;
  final Color b;

  // (x, y, w, h) na grade 24×24
  static const _bars = [
    (4.0, 2.0, 14.0, 4.0),
    (4.0, 7.5, 8.0, 4.0),
    (10.0, 13.0, 8.0, 4.0),
    (4.0, 18.5, 14.0, 4.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    for (var i = 0; i < _bars.length; i++) {
      final (x, y, w, h) = _bars[i];
      final paint = Paint()..color = i.isEven ? a : b;
      canvas.drawRect(Rect.fromLTWH(x * k, y * k, w * k, h * k), paint);
    }
  }

  @override
  bool shouldRepaint(_BrandIconPainter old) => old.a != a || old.b != b;
}

/// Assinatura da marca: bloco tinta com o ícone + wordmark ao lado.
/// `servicereport` sempre em caixa baixa, uma palavra. Com [over] mostra a
/// linha "leiano" acima do wordmark (uso institucional / splash).
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.iconSize = 26,
    this.wordSize = 19,
    this.onDark = false,
    this.showOver = false,
  });

  final double iconSize;
  final double wordSize;
  final bool onDark;
  final bool showOver;

  @override
  Widget build(BuildContext context) {
    final wordColor = onDark ? Colors.white : BrandColor.ink;
    final block = iconSize + 24;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: block,
          height: block,
          color: BrandColor.ink,
          alignment: Alignment.center,
          child: BrandIcon(size: iconSize, onDark: true, mono: false),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showOver) ...[
              Text(
                'leiano',
                style: BrandText.brandOver.copyWith(
                  color: onDark ? BrandColor.textDisabled : BrandColor.textTertiary,
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              'servicereport',
              style: BrandText.brandWord.copyWith(
                fontSize: wordSize,
                color: wordColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
