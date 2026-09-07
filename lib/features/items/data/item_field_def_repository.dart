import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';
import 'item_field_def_mapper.dart';

/// Definições de campo personalizado de item + suas opções. Leitura de
/// referência (REST-only, §8.4) cacheada em drift para o form do item
/// funcionar offline. O CRUD (admin/escritório) é sempre online.
class ItemFieldDefRepository {
  ItemFieldDefRepository(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  String get _orgId => _ref.read(organizationIdProvider);
  Dio get _dio => _ref.read(apiClientProvider).businessDio;

  Stream<List<LocalItemFieldDef>> watchDefs() {
    final q = _db.select(_db.localItemFieldDefs)
      ..orderBy([
        (t) => OrderingTerm(expression: t.position),
        (t) => OrderingTerm(expression: t.label),
      ]);
    return q.watch();
  }

  Stream<List<LocalItemFieldOption>> watchOptions(String fieldDefId) {
    final q = _db.select(_db.localItemFieldOptions)
      ..where((t) => t.fieldDefId.equals(fieldDefId))
      ..orderBy([(t) => OrderingTerm(expression: t.position)]);
    return q.watch();
  }

  /// Melhor esforço — a tela do item / de admin chama ao abrir.
  Future<void> refresh() async {
    final r = await restCall(() => _dio.get('/v1/item-field-defs'));
    final raw =
        (r.data as Map<String, dynamic>)['item_field_defs'] as List? ??
        const [];
    await _db.transaction(() async {
      await _db.delete(_db.localItemFieldDefs).go();
      await _db.delete(_db.localItemFieldOptions).go();
      for (final e in raw) {
        final j = e as Map<String, dynamic>;
        await _db
            .into(_db.localItemFieldDefs)
            .insertOnConflictUpdate(
              itemFieldDefFromApiJson(j, organizationId: _orgId),
            );
        for (final o in itemFieldOptionsFromApiJson(
          j,
          organizationId: _orgId,
        )) {
          await _db.into(_db.localItemFieldOptions).insertOnConflictUpdate(o);
        }
      }
    });
  }

  Future<void> create({
    String? itemTypeId,
    required String label,
    required String dataType,
    required bool required,
    int position = 0,
    List<({String label, String value})> options = const [],
  }) async {
    await restCall(
      () => _dio.post(
        '/v1/item-field-defs',
        data: {
          'item_type_id': ?itemTypeId,
          'label': label,
          'data_type': dataType,
          'required': required,
          'position': position,
          'options': [
            for (final o in options) {'label': o.label, 'value': o.value},
          ],
        },
      ),
    );
    await refresh();
  }

  Future<void> update({
    required String id,
    required int? baseVersion,
    String? itemTypeId,
    required String label,
    required String dataType,
    required bool required,
    int position = 0,
    List<({String label, String value})> options = const [],
  }) async {
    await restCall(
      () => _dio.patch(
        '/v1/item-field-defs/$id',
        data: {
          'version': ?baseVersion,
          'item_type_id': ?itemTypeId,
          'label': label,
          'data_type': dataType,
          'required': required,
          'position': position,
          'options': [
            for (final o in options) {'label': o.label, 'value': o.value},
          ],
        },
      ),
    );
    await refresh();
  }

  Future<void> delete(String id) async {
    await restCall(() => _dio.delete('/v1/item-field-defs/$id'));
    await refresh();
  }
}

final itemFieldDefRepositoryProvider = Provider<ItemFieldDefRepository>(
  (ref) => ItemFieldDefRepository(ref),
);

/// Todos os defs (globais + de todos os tipos).
final itemFieldDefListProvider = StreamProvider<List<LocalItemFieldDef>>(
  (ref) => ref.watch(itemFieldDefRepositoryProvider).watchDefs(),
);

/// Defs aplicáveis a um item de um dado tipo: globais (`itemTypeId == null`) +
/// os daquele tipo. `null` = item sem tipo → só os globais.
final itemFieldDefsForTypeProvider =
    Provider.family<List<LocalItemFieldDef>, String?>((ref, typeId) {
      final all = ref.watch(itemFieldDefListProvider).value ?? const [];
      return [
        for (final d in all)
          if (d.itemTypeId == null || d.itemTypeId == typeId) d,
      ];
    });

final itemFieldOptionsProvider =
    StreamProvider.family<List<LocalItemFieldOption>, String>(
      (ref, defId) =>
          ref.watch(itemFieldDefRepositoryProvider).watchOptions(defId),
    );
