import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../sync/application/sync_provider.dart';

/// Clientes locais (bootstrap/pull já aplicados), ordenados por nome —
/// `.watch()` do Drift reemite sozinho a cada escrita na tabela, então a
/// tela nunca precisa de um `setState` manual pra refletir uma sincronização.
final clientListProvider = StreamProvider<List<LocalClient>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.localClients)
    ..where((t) => t.deleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.name)]);
  return query.watch();
});

final clientByIdProvider = StreamProvider.family<LocalClient?, String>((
  ref,
  id,
) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.localClients)..where((t) => t.id.equals(id));
  return query.watchSingleOrNull();
});
