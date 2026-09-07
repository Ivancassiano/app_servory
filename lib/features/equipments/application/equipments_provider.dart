import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/paged_source.dart';
import '../../../core/db/app_database.dart';
import '../data/equipment_repository.dart';

export '../data/equipment_repository.dart' show equipmentRepositoryProvider;
export '../data/equipment_type_repository.dart'
    show equipmentTypeListProvider, equipmentTypeRepositoryProvider;

/// Delegam ao [equipmentRepositoryProvider] (drift no app, REST no web).
/// Sem cache de `equipment_type` ainda (Fatia 2) — a lista mostra
/// nome/marca/modelo/série, não o tipo.
final equipmentListProvider = StreamProvider<List<LocalEquipment>>(
  (ref) => ref.watch(equipmentRepositoryProvider).watchList(),
);

/// Fonte paginada da lista (só web) — nula nos apps.
final equipmentListPagingProvider = Provider<PagedSource?>(
  (ref) => pagingOf(ref.watch(equipmentRepositoryProvider)),
);

final equipmentByIdProvider = StreamProvider.family<LocalEquipment?, String>(
  (ref, id) => ref.watch(equipmentRepositoryProvider).watchById(id),
);
