import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../sync/application/sync_provider.dart';

/// Só edição nesta entrega, mesmo motivo do `LocationEditController` —
/// criar exige escolher local e tipo de equipamento (UI de seleção ainda
/// não existe). Campos sensíveis (`serial_number`, `cost`) ficam de fora
/// do formulário por ora — o app ainda não sabe se o ator tem permissão de
/// escrita nesses campos (a máscara é só de leitura hoje, GUIA-FLUTTER §4).
class EquipmentEditController {
  EquipmentEditController(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  Future<void> update({
    required String equipmentId,
    required String name,
    required String brand,
    required String model,
    required String notes,
  }) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      final current = await (_db.select(
        _db.localEquipments,
      )..where((t) => t.id.equals(equipmentId))).getSingle();

      await (_db.update(
        _db.localEquipments,
      )..where((t) => t.id.equals(equipmentId))).write(
        LocalEquipmentsCompanion(
          name: Value(name),
          brand: Value(brand),
          model: Value(model),
          notes: Value(notes),
          localUpdatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );
      await _db
          .into(_db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              operationId: const Uuid().v4(),
              organizationId: current.organizationId,
              entityType: 'equipment',
              entityId: equipmentId,
              operationType: 'update',
              payload: jsonEncode({
                'name': name,
                'brand': brand,
                'model': model,
                'notes': notes,
              }),
              baseVersion: Value(current.version),
              occurredAt: now,
            ),
          );
    });

    unawaited(_trySyncNow());
  }

  Future<void> _trySyncNow() async {
    try {
      await _ref.read(syncRunnerProvider.notifier).runSync();
    } catch (_) {
      // silencioso de propósito: outbox já garante retry depois.
    }
  }
}

final equipmentEditControllerProvider = Provider<EquipmentEditController>(
  (ref) => EquipmentEditController(ref),
);
