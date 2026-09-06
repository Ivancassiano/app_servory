import 'package:flutter/widgets.dart';

/// No web não há fila local de anexos (upload é sempre online e imediato),
/// então nunca há um "arquivo pendente" para pré-visualizar.
Widget localFileImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) => const SizedBox.shrink();
