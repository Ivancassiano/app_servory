import 'dart:io';

import 'package:flutter/widgets.dart';

/// Prévia de um arquivo local (anexo ainda não enviado). Só existe no
/// caminho nativo — no web não há fila local de anexos.
Widget localFileImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
  );
}
