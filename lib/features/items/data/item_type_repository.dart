import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/remote_collection.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';
import 'item_type_mapper.dart';

/// Tipos de item — leitura de referência (REST-only, §8.4). No app é cacheado
/// em drift para o seletor de "novo item" funcionar offline (precisa ter
/// ficado online ao menos uma vez); no web, só memória.
abstract interface class ItemTypeRepository {
  Stream<List<LocalItemType>> watchList();
  Future<void> refresh();
}

final itemTypeRepositoryProvider = Provider<ItemTypeRepository>((ref) {
  final orgId = ref.watch(organizationIdProvider);
  if (kIsWeb) {
    final repo = _RemoteItemTypeRepository(
      ref.watch(apiClientProvider).businessDio,
      orgId,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return _LocalItemTypeRepository(ref);
});

final itemTypeListProvider = StreamProvider<List<LocalItemType>>(
  (ref) => ref.watch(itemTypeRepositoryProvider).watchList(),
);

// ---------------------------------------------------------------------------

class _LocalItemTypeRepository implements ItemTypeRepository {
  _LocalItemTypeRepository(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  String get _orgId => _ref.read(organizationIdProvider);

  @override
  Stream<List<LocalItemType>> watchList() {
    final q = _db.select(_db.localItemTypes)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return q.watch();
  }

  @override
  Future<void> refresh() async {
    final dio = _ref.read(apiClientProvider).businessDio;
    final r = await restCall(() => dio.get('/v1/item-types'));
    final raw =
        (r.data as Map<String, dynamic>)['item_types'] as List? ?? const [];
    // `/v1/item-types` já devolve a lista completa e viva (sem os
    // excluídos). Substitui o cache inteiro — só upsert deixaria tipo
    // apagado no servidor preso no seletor de item (§8.4).
    await _db.transaction(() async {
      await _db.delete(_db.localItemTypes).go();
      for (final e in raw) {
        await _db
            .into(_db.localItemTypes)
            .insertOnConflictUpdate(
              itemTypeFromApiJson(
                e as Map<String, dynamic>,
                organizationId: _orgId,
              ),
            );
      }
    });
  }
}

// ---------------------------------------------------------------------------

class _RemoteItemTypeRepository implements ItemTypeRepository {
  _RemoteItemTypeRepository(Dio dio, String orgId)
    : _collection = RemoteCollection<LocalItemType>(
        dio: dio,
        listPath: '/v1/item-types',
        listKey: 'item_types',
        fromJson: (j) => itemTypeFromApiJson(j, organizationId: orgId),
        idOf: (t) => t.id,
      );

  final RemoteCollection<LocalItemType> _collection;

  void dispose() => _collection.dispose();

  @override
  Stream<List<LocalItemType>> watchList() => _collection.watchList();

  @override
  Future<void> refresh() => _collection.refresh();
}
