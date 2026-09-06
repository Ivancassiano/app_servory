import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../sync/application/sync_provider.dart';

/// Criar um equipamento fica pra quando a UI tiver seleção de local/tipo —
/// editar um já sincronizado não precisa disso (`EquipmentEditController`).
/// Sem cache de `equipment_type` (REST-only), a lista mostra nome/marca/
/// modelo/série, não o tipo.
final equipmentListProvider = StreamProvider<List<LocalEquipment>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.localEquipments)
    ..where((t) => t.deleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.name)]);
  return query.watch();
});

final equipmentByIdProvider = StreamProvider.family<LocalEquipment?, String>((
  ref,
  id,
) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.localEquipments)..where((t) => t.id.equals(id));
  return query.watchSingleOrNull();
});
