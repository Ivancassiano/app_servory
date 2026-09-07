import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';
import '../../sync/data/local_first_repository.dart';
import 'item_field_value_mapper.dart';

/// Valor tipado de um campo personalizado para um item.
class TypedFieldValue {
  const TypedFieldValue({this.text, this.number, this.datetime, this.boolean});

  final String? text;
  final double? number;
  final DateTime? datetime;
  final bool? boolean;

  bool get isEmpty =>
      text == null && number == null && datetime == null && boolean == null;

  /// Escalar cru para o corpo REST `PUT /v1/items/{id}/fields` e para o
  /// payload de sync (o backend coage pelo `data_type` do def).
  Object? get raw {
    if (boolean != null) return boolean;
    if (number != null) return number;
    if (datetime != null) return datetime!.toUtc().toIso8601String();
    return text;
  }
}

abstract interface class ItemFieldValueRepository {
  Stream<List<LocalItemFieldValue>> watchByItem(String itemId);

  /// Substitui o conjunto de valores de um item de uma vez. Online-first:
  /// online → `PUT /v1/items/{id}/fields`; offline → grava local + enfileira
  /// operações `item_field_value` por linha.
  Future<void> setValues(String itemId, Map<String, TypedFieldValue> byDefId);
}

final itemFieldValueRepositoryProvider = Provider<ItemFieldValueRepository>((
  ref,
) {
  if (kIsWeb) return _RemoteItemFieldValueRepository(ref);
  return _LocalFirstItemFieldValueRepository(ref);
});

final itemFieldValuesProvider =
    StreamProvider.family<List<LocalItemFieldValue>, String>(
      (ref, itemId) =>
          ref.watch(itemFieldValueRepositoryProvider).watchByItem(itemId),
    );

// ---------------------------------------------------------------------------

Map<String, dynamic> _putBody(Map<String, TypedFieldValue> byDefId) => {
  'values': [
    for (final e in byDefId.entries)
      {'field_def_id': e.key, 'value': e.value.isEmpty ? null : e.value.raw},
  ],
};

class _LocalFirstItemFieldValueRepository extends LocalFirstRepositoryBase
    implements ItemFieldValueRepository {
  _LocalFirstItemFieldValueRepository(super.ref);

  @override
  Stream<List<LocalItemFieldValue>> watchByItem(String itemId) => (db.select(
    db.localItemFieldValues,
  )..where((t) => t.itemId.equals(itemId) & t.deleted.equals(false))).watch();

  Future<List<LocalItemFieldValue>> _current(String itemId) => (db.select(
    db.localItemFieldValues,
  )..where((t) => t.itemId.equals(itemId) & t.deleted.equals(false))).get();

  @override
  Future<void> setValues(
    String itemId,
    Map<String, TypedFieldValue> byDefId,
  ) async {
    if (online) {
      try {
        final r = await restCall(
          () => dio.put('/v1/items/$itemId/fields', data: _putBody(byDefId)),
        );
        final rows =
            (r.data as Map<String, dynamic>)['field_values'] as List? ??
            const [];
        await db.transaction(() async {
          await (db.delete(
            db.localItemFieldValues,
          )..where((t) => t.itemId.equals(itemId))).go();
          for (final e in rows) {
            await db
                .into(db.localItemFieldValues)
                .insertOnConflictUpdate(
                  itemFieldValueFromApiJson(
                    e as Map<String, dynamic>,
                    organizationId: orgId,
                  ),
                );
          }
        });
        return;
      } on Object {
        // cai pro caminho offline
      }
    }
    await db.transaction(() async {
      final existing = await _current(itemId);
      final byDef = {for (final v in existing) v.fieldDefId: v};
      for (final e in byDefId.entries) {
        final cur = byDef[e.key];
        if (e.value.isEmpty) {
          if (cur != null) {
            await (db.update(
              db.localItemFieldValues,
            )..where((t) => t.id.equals(cur.id))).write(
              const LocalItemFieldValuesCompanion(
                deleted: Value(true),
                syncStatus: Value('pending'),
              ),
            );
            await enqueue(
              entityType: 'item_field_value',
              entityId: cur.id,
              operationType: 'delete',
              payload: const {},
            );
          }
          continue;
        }
        if (cur == null) {
          final id = const Uuid().v4();
          await db
              .into(db.localItemFieldValues)
              .insert(
                LocalItemFieldValuesCompanion.insert(
                  id: id,
                  organizationId: orgId,
                  itemId: itemId,
                  fieldDefId: e.key,
                  valueText: Value(e.value.text),
                  valueNumber: Value(e.value.number),
                  valueDatetime: Value(e.value.datetime),
                  valueBoolean: Value(e.value.boolean),
                  localUpdatedAt: DateTime.now(),
                  syncStatus: const Value('pending'),
                  lastSyncedAt: const Value(null),
                ),
              );
          await enqueue(
            entityType: 'item_field_value',
            entityId: id,
            operationType: 'create',
            payload: {
              'item_id': itemId,
              'field_def_id': e.key,
              'value': e.value.raw,
            },
          );
        } else {
          await (db.update(
            db.localItemFieldValues,
          )..where((t) => t.id.equals(cur.id))).write(
            LocalItemFieldValuesCompanion(
              valueText: Value(e.value.text),
              valueNumber: Value(e.value.number),
              valueDatetime: Value(e.value.datetime),
              valueBoolean: Value(e.value.boolean),
              localUpdatedAt: Value(DateTime.now()),
              syncStatus: const Value('pending'),
            ),
          );
          await enqueue(
            entityType: 'item_field_value',
            entityId: cur.id,
            operationType: 'update',
            payload: {'value': e.value.raw},
            baseVersion: cur.version,
          );
        }
      }
      // defs que sumiram do conjunto novo → soft-delete + enfileira
      for (final v in existing) {
        if (!byDefId.containsKey(v.fieldDefId)) {
          await (db.update(
            db.localItemFieldValues,
          )..where((t) => t.id.equals(v.id))).write(
            const LocalItemFieldValuesCompanion(
              deleted: Value(true),
              syncStatus: Value('pending'),
            ),
          );
          await enqueue(
            entityType: 'item_field_value',
            entityId: v.id,
            operationType: 'delete',
            payload: const {},
          );
        }
      }
    });
    unawaited(trySyncNow());
  }
}

// ---------------------------------------------------------------------------

/// Web: sem cache local, só o PUT direto. Watch devolve vazio (a tela do
/// item no web recarrega via REST — fora do escopo desta entrega).
class _RemoteItemFieldValueRepository implements ItemFieldValueRepository {
  _RemoteItemFieldValueRepository(this._ref);
  final Ref _ref;

  @override
  Stream<List<LocalItemFieldValue>> watchByItem(String itemId) =>
      Stream.value(const []);

  @override
  Future<void> setValues(
    String itemId,
    Map<String, TypedFieldValue> byDefId,
  ) async {
    final dio = _ref.read(apiClientProvider).businessDio;
    await restCall(
      () => dio.put('/v1/items/$itemId/fields', data: _putBody(byDefId)),
    );
  }
}
