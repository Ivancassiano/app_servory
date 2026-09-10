import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cabeçalho preto das telas de lista/detalhe (handoff): título grande em
/// Space Grotesk, com uma linha de contagem em IBM Plex Mono caixa alta
/// acima quando faz sentido ("14 ORDENS") e, opcionalmente, um subtítulo
/// abaixo (ex.: o cliente quando a lista está recortada por ele).
PreferredSizeWidget brandAppBar({
  required String title,
  String? count,
  String? subtitle,
  List<Widget>? actions,
  Widget? leading,
  double titleSize = 21,
}) {
  var toolbarHeight = kToolbarHeight;
  if (count != null) toolbarHeight += 18;
  if (subtitle != null) toolbarHeight += 18;

  return AppBar(
    toolbarHeight: toolbarHeight,
    titleSpacing: 16,
    leading: leading,
    title: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (count != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              count.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 9,
                letterSpacing: 1.5,
                color: BrandColor.onDarkSecondary,
              ),
            ),
          ),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: titleSize,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
            color: Colors.white,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              subtitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 12,
                color: BrandColor.onDarkSecondary,
              ),
            ),
          ),
      ],
    ),
    actions: actions,
  );
}
