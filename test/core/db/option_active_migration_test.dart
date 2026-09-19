import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

void main() {
  test('v17 → v18: opções em cache ganham is_active = true, sem perder dados', () async {
    // Banco no schema antigo (sem is_active), como está no aparelho de quem
    // atualiza o app.
    final raw = sql.sqlite3.openInMemory()
      ..execute('''
        CREATE TABLE local_item_field_options (
          id TEXT NOT NULL PRIMARY KEY,
          organization_id TEXT NOT NULL,
          field_def_id TEXT NOT NULL,
          label TEXT NOT NULL,
          value TEXT NOT NULL,
          position INTEGER NOT NULL DEFAULT 0,
          cached_at INTEGER NOT NULL
        )''')
      ..execute(
        "INSERT INTO local_item_field_options VALUES "
        "('o1','org','d1','Azul','Azul',0,0)",
      )
      ..execute('PRAGMA user_version = 17');

    final db = AppDatabase.forTesting(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final rows = await db.select(db.localItemFieldOptions).get();
    expect(rows, hasLength(1));
    expect(rows.single.label, 'Azul');
    expect(rows.single.value, 'Azul'); // valor antigo (= rótulo) preservado
    expect(rows.single.isActive, isTrue);
  });
}
