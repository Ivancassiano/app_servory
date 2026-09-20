import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

void main() {
  test(
    'v18 → v19: client_id da tarefa vira opcional, cursor de sync zera',
    () async {
      // Banco no schema antigo (client_id NOT NULL), como está no aparelho
      // de quem atualiza o app (ADR-0026 no servidor).
      final raw = sql.sqlite3.openInMemory()
        ..execute('''
          CREATE TABLE local_tasks (
            id TEXT NOT NULL PRIMARY KEY,
            organization_id TEXT NOT NULL,
            client_id TEXT NOT NULL,
            local_updated_at INTEGER NOT NULL,
            description TEXT NOT NULL DEFAULT ''
          )''')
        ..execute(
          "INSERT INTO local_tasks VALUES ('t1','org','c1',0,'Antiga')",
        )
        ..execute('''
          CREATE TABLE local_sync_state (
            organization_id TEXT NOT NULL PRIMARY KEY,
            cursor INTEGER NOT NULL DEFAULT 0
          )''')
        ..execute("INSERT INTO local_sync_state VALUES ('org', 42)")
        ..execute('PRAGMA user_version = 18');

      final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);

      // A tabela antiga foi dropada e recriada vazia — o próximo pull (cursor
      // zerado abaixo) é quem repovoa, junto com os alvos.
      final tasks = await db.select(db.localTasks).get();
      expect(tasks, isEmpty);

      // Cursor de sync zerado: o próximo pull reprocessa o histórico inteiro.
      final syncState = await db.select(db.localSyncState).get();
      expect(syncState, isEmpty);

      // client_id agora aceita nulo (tarefa interna, sem cliente).
      await db
          .into(db.localTasks)
          .insert(
            LocalTasksCompanion.insert(
              id: 't2',
              organizationId: 'org',
              localUpdatedAt: DateTime.now(),
              clientId: const Value(null),
            ),
          );
      final reloaded = await (db.select(
        db.localTasks,
      )..where((t) => t.id.equals('t2'))).getSingle();
      expect(reloaded.clientId, null);
    },
  );
}
