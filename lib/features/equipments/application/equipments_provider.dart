import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../sync/application/sync_provider.dart';

/// Só leitura nesta entrega (GUIA-FLUTTER.md §8.4) — sem cache de
/// `equipment_type` (REST-only), a lista mostra nome/marca/modelo/série,
/// não o tipo (contexto no plano desta fatia).
final equipmentListProvider = StreamProvider<List<LocalEquipment>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.localEquipments)
    ..where((t) => t.deleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.name)]);
  return query.watch();
});
