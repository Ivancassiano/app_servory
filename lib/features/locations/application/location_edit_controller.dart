import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../sync/application/sync_provider.dart';

/// Só edição nesta entrega — criar um local exige escolher o cliente (e,
/// opcionalmente, o pai na hierarquia), uma UI de seleção que ainda não
/// existe; editar um local já sincronizado não precisa disso. Mesmo padrão
/// local-primeiro do `ClientEditController`.
class LocationEditController {
  LocationEditController(this._ref);
  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  Future<void> update({
    required String locationId,
    required String name,
    required String contactPerson,
    required String phone,
    required String notes,
  }) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      final current = await (_db.select(
        _db.localLocations,
      )..where((t) => t.id.equals(locationId))).getSingle();

      await (_db.update(
        _db.localLocations,
      )..where((t) => t.id.equals(locationId))).write(
        LocalLocationsCompanion(
          name: Value(name),
          contactPerson: Value(contactPerson),
          phone: Value(phone),
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
              entityType: 'location',
              entityId: locationId,
              operationType: 'update',
              payload: jsonEncode({
                'name': name,
                'contact_person': contactPerson,
                'phone': phone,
                'notes': notes,
              }),
              baseVersion: Value(current.version),
              occurredAt: now,
            ),
          );
    });

    unawaited(_trySyncNow());
  }

  /// Melhor esforço: se estiver offline ou a chamada falhar, a linha já
  /// está gravada localmente e será enviada na próxima sincronização.
  Future<void> _trySyncNow() async {
    try {
      await _ref.read(syncRunnerProvider.notifier).runSync();
    } catch (_) {
      // silencioso de propósito: outbox já garante retry depois.
    }
  }
}

final locationEditControllerProvider = Provider<LocationEditController>(
  (ref) => LocationEditController(ref),
);
