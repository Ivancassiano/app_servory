import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../sync/application/sync_provider.dart';

/// Criar um local fica pra quando a UI tiver seleção de cliente/pai —
/// editar um já sincronizado não precisa disso (`LocationEditController`).
final locationListProvider = StreamProvider<List<LocalLocation>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.localLocations)
    ..where((t) => t.deleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.name)]);
  return query.watch();
});

final locationByIdProvider = StreamProvider.family<LocalLocation?, String>((
  ref,
  id,
) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.localLocations)..where((t) => t.id.equals(id));
  return query.watchSingleOrNull();
});
