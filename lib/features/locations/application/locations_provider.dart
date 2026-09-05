import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../sync/application/sync_provider.dart';

/// Só leitura nesta entrega (GUIA-FLUTTER.md §8.4) — criar/editar local
/// fica para quando `location` ganhar outbox própria, igual `client`.
final locationListProvider = StreamProvider<List<LocalLocation>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.localLocations)
    ..where((t) => t.deleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.name)]);
  return query.watch();
});
