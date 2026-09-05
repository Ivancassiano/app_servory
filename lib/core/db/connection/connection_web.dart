import 'package:drift/drift.dart';

/// O Chrome roda sempre online (decisão de produto) — não existe banco
/// local nesse alvo, então nada deveria chamar isto lá. Existe só para o
/// build web compilar (o arquivo que usa `dart:ffi` nunca é importado no
/// alvo web, graças ao export condicional em `connection.dart`).
QueryExecutor connectToOrganizationDatabase(String organizationId) {
  throw UnsupportedError(
    'Banco local não existe no Chrome — o app web roda sempre online.',
  );
}
