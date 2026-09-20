import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

void main() {
  test(
    'v19 → v20: client_id de local/item vira opcional, cursor de sync zera',
    () async {
      // Banco no schema antigo (client_id NOT NULL nas duas tabelas), como
      // está no aparelho de quem atualiza o app (ADR-0027 no servidor).
      final raw = sql.sqlite3.openInMemory()
        ..execute('''
          CREATE TABLE local_locations (
            id TEXT NOT NULL PRIMARY KEY,
            organization_id TEXT NOT NULL,
            client_id TEXT NOT NULL,
            local_updated_at INTEGER NOT NULL,
            name TEXT NOT NULL DEFAULT ''
          )''')
        ..execute("INSERT INTO local_locations VALUES ('l1','org','c1',0,'Antiga')")
        ..execute('''
          CREATE TABLE local_items (
            id TEXT NOT NULL PRIMARY KEY,
            organization_id TEXT NOT NULL,
            client_id TEXT NOT NULL,
            local_updated_at INTEGER NOT NULL,
            name TEXT NOT NULL DEFAULT ''
          )''')
        ..execute("INSERT INTO local_items VALUES ('i1','org','c1',0,'Antigo')")
        ..execute('''
          CREATE TABLE local_sync_state (
            organization_id TEXT NOT NULL PRIMARY KEY,
            cursor INTEGER NOT NULL DEFAULT 0
          )''')
        ..execute("INSERT INTO local_sync_state VALUES ('org', 42)")
        ..execute('PRAGMA user_version = 19');

      final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);

      // As tabelas antigas foram dropadas e recriadas vazias — o próximo
      // pull (cursor zerado abaixo) é quem repovoa.
      expect(await db.select(db.localLocations).get(), isEmpty);
      expect(await db.select(db.localItems).get(), isEmpty);

      // Cursor de sync zerado: o próximo pull reprocessa o histórico inteiro.
      expect(await db.select(db.localSyncState).get(), isEmpty);

      // client_id agora aceita nulo em ambas.
      await db
          .into(db.localLocations)
          .insert(
            LocalLocationsCompanion.insert(
              id: 'l2',
              organizationId: 'org',
              localUpdatedAt: DateTime.now(),
              clientId: const Value(null),
            ),
          );
      await db
          .into(db.localItems)
          .insert(
            LocalItemsCompanion.insert(
              id: 'i2',
              organizationId: 'org',
              localUpdatedAt: DateTime.now(),
              name: 'Interno',
              clientId: const Value(null),
            ),
          );
      final loc = await (db.select(
        db.localLocations,
      )..where((t) => t.id.equals('l2'))).getSingle();
      final it = await (db.select(
        db.localItems,
      )..where((t) => t.id.equals('i2'))).getSingle();
      expect(loc.clientId, null);
      expect(it.clientId, null);
    },
  );
}
