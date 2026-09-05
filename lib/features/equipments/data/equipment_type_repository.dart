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
import 'equipment_type_mapper.dart';

/// Tipos de equipamento — leitura de referência (REST-only, §8.4). No app é
/// cacheado em drift para o seletor de "novo equipamento" funcionar offline
/// (precisa ter ficado online ao menos uma vez); no web, só memória.
abstract interface class EquipmentTypeRepository {
  Stream<List<LocalEquipmentType>> watchList();

  /// Busca do servidor. Melhor esforço — a tela chama ao abrir.
  Future<void> refresh();
}

final equipmentTypeRepositoryProvider = Provider<EquipmentTypeRepository>((ref) {
  final orgId = ref.watch(organizationIdProvider);
  if (kIsWeb) {
    final repo = _RemoteEquipmentTypeRepository(
      ref.watch(apiClientProvider).businessDio,
      orgId,
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return _LocalEquipmentTypeRepository(ref);
});

final equipmentTypeListProvider = StreamProvider<List<LocalEquipmentType>>(
  (ref) => ref.watch(equipmentTypeRepositoryProvider).watchList(),
);

// ---------------------------------------------------------------------------

class _LocalEquipmentTypeRepository implements EquipmentTypeRepository {
  _LocalEquipmentTypeRepository(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  String get _orgId => _ref.read(organizationIdProvider);

  @override
  Stream<List<LocalEquipmentType>> watchList() {
    final q = _db.select(_db.localEquipmentTypes)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return q.watch();
  }

  @override
  Future<void> refresh() async {
    final dio = _ref.read(apiClientProvider).businessDio;
    final r = await restCall(() => dio.get('/v1/equipment-types'));
    final raw =
        (r.data as Map<String, dynamic>)['equipment_types'] as List? ??
        const [];
    await _db.transaction(() async {
      for (final e in raw) {
        await _db.into(_db.localEquipmentTypes).insertOnConflictUpdate(
              equipmentTypeFromApiJson(
                e as Map<String, dynamic>,
                organizationId: _orgId,
              ),
            );
      }
    });
  }
}

// ---------------------------------------------------------------------------

class _RemoteEquipmentTypeRepository implements EquipmentTypeRepository {
  _RemoteEquipmentTypeRepository(Dio dio, String orgId)
    : _collection = RemoteCollection<LocalEquipmentType>(
        dio: dio,
        listPath: '/v1/equipment-types',
        listKey: 'equipment_types',
        fromJson: (j) => equipmentTypeFromApiJson(j, organizationId: orgId),
        idOf: (t) => t.id,
      );

  final RemoteCollection<LocalEquipmentType> _collection;

  void dispose() => _collection.dispose();

  @override
  Stream<List<LocalEquipmentType>> watchList() => _collection.watchList();

  @override
  Future<void> refresh() => _collection.refresh();
}
