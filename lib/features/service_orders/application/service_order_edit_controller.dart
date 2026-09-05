import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/service_order_repository.dart';

/// Fachada fina para a tela — a lógica online-first / offline (incluindo as
/// ações nomeadas `start`/`complete`/`reopen`, ADR-0018) vive no
/// [ServiceOrderRepository]. `clientId` só existe na criação (imutável).
class ServiceOrderEditController {
  ServiceOrderEditController(this._ref);
  final Ref _ref;

  ServiceOrderRepository get _repo =>
      _ref.read(serviceOrderRepositoryProvider);

  Future<String> create({
    required String clientId,
    String? locationId,
    String? equipmentId,
    required bool open,
    required String reason,
  }) => _repo.create(
    clientId: clientId,
    locationId: locationId,
    equipmentId: equipmentId,
    open: open,
    reason: reason,
  );

  Future<void> update({
    required String serviceOrderId,
    int? baseVersion,
    String? locationId,
    String? equipmentId,
    required String reason,
    required String diagnosis,
    required String workPerformed,
    required String finalCondition,
    required String notes,
  }) => _repo.update(
    id: serviceOrderId,
    baseVersion: baseVersion,
    locationId: locationId,
    equipmentId: equipmentId,
    reason: reason,
    diagnosis: diagnosis,
    workPerformed: workPerformed,
    finalCondition: finalCondition,
    notes: notes,
  );

  Future<void> start(String id, {int? baseVersion}) =>
      _repo.transition(id: id, baseVersion: baseVersion, action: 'start');

  Future<void> complete(String id, {int? baseVersion}) =>
      _repo.transition(id: id, baseVersion: baseVersion, action: 'complete');

  Future<void> reopen(String id, {int? baseVersion}) =>
      _repo.transition(id: id, baseVersion: baseVersion, action: 'reopen');
}

final serviceOrderEditControllerProvider = Provider<ServiceOrderEditController>(
  (ref) => ServiceOrderEditController(ref),
);
