import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../storage/secure_store.dart';
import '../db_key_store.dart';

/// Abre o banco criptografado desta organização em
/// `servory-{organization_id}.sqlite`, dentro do diretório de suporte do
/// app (não visível ao usuário/Arquivos, ao contrário de Documents — spec
/// §18.2). `LazyDatabase` adia a conexão de verdade até o primeiro uso,
/// permitindo os `await`s (diretório, chave) antes de abrir.
QueryExecutor connectToOrganizationDatabase(String organizationId) {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'servory-$organizationId.sqlite'));
    final hexKey = await DbKeyStore(
      SecureStore(),
    ).getOrCreateHexKey(organizationId);

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = \"x'$hexKey'\";");
      },
    );
  });
}
