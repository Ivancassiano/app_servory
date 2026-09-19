import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_controller.dart';
import '../../sync/application/sync_provider.dart';
import 'item_field_def_mapper.dart';

/// Uma opção de lista como o editor a envia: `id == null` = opção nova; com
/// `id` só a descrição e o ativo/inativo mudam (o código que os itens guardam
/// nunca muda). A ordem da lista é a posição.
typedef FieldOptionInput = ({String? id, String label, bool active});

Map<String, dynamic> _optionJson(FieldOptionInput o) => {
  'id': ?o.id,
  'label': o.label,
  'is_active': o.active,
};

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

  /// Todas as opções, agrupadas por campo (ativas e inativas).
  Stream<Map<String, List<LocalItemFieldOption>>> watchAllOptions() {
    final q = _db.select(_db.localItemFieldOptions)
      ..orderBy([(t) => OrderingTerm(expression: t.position)]);
    return q.watch().map((rows) {
      final byDef = <String, List<LocalItemFieldOption>>{};
      for (final o in rows) {
        byDef.putIfAbsent(o.fieldDefId, () => []).add(o);
      }
      return byDef;
    });
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
    List<FieldOptionInput> options = const [],
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
          'options': [for (final o in options) _optionJson(o)],
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
    List<FieldOptionInput> options = const [],
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
          'options': [for (final o in options) _optionJson(o)],
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

/// Todas as opções (ativas e inativas) de todos os campos, por `field_def_id` —
/// para exibir o rótulo do valor já gravado num item.
final itemFieldOptionsByDefProvider =
    StreamProvider<Map<String, List<LocalItemFieldOption>>>(
      (ref) => ref.watch(itemFieldDefRepositoryProvider).watchAllOptions(),
    );

/// Texto a exibir para o valor gravado (`value`) de um campo lista: o rótulo da
/// opção — inclusive se ela foi inativada. Se a lista ainda não carregou devolve
/// vazio (não mostra o código); se carregou e a opção não existe (dado antigo),
/// devolve o valor cru.
String selectOptionLabel(List<LocalItemFieldOption> options, String value) {
  for (final o in options) {
    if (o.value == value) return o.label;
  }
  return options.isEmpty ? '' : value;
}

final itemFieldOptionsProvider =
    StreamProvider.family<List<LocalItemFieldOption>, String>(
      (ref, defId) =>
          ref.watch(itemFieldDefRepositoryProvider).watchOptions(defId),
    );
