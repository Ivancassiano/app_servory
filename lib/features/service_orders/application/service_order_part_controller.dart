import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/service_order_repository.dart';

/// Fachada fina — lógica online-first / offline no [ServiceOrderRepository].
/// `unitCost`/`unitPrice` são sensíveis (grupo `cost`); o app não checa
/// permissão de escrita antes de mandar — um 422 aparece como erro genérico.
class ServiceOrderPartController {
  ServiceOrderPartController(this._ref);
  final Ref _ref;

  ServiceOrderRepository get _repo =>
      _ref.read(serviceOrderRepositoryProvider);

  Future<void> addPart({
    required String serviceOrderId,
    required String description,
    required String partNumber,
    required String quantity,
    required String unit,
    required String unitCost,
    required String unitPrice,
    required String notes,
  }) => _repo.addPart(
    orderId: serviceOrderId,
    description: description,
    partNumber: partNumber,
    quantity: quantity,
    unit: unit,
    unitCost: unitCost,
    unitPrice: unitPrice,
    notes: notes,
  );

  Future<void> updatePart({
    required String serviceOrderId,
    required String partId,
    int? baseVersion,
    required String description,
    required String partNumber,
    required String quantity,
    required String unit,
    required String unitCost,
    required String unitPrice,
    required String notes,
  }) => _repo.updatePart(
    orderId: serviceOrderId,
    partId: partId,
    baseVersion: baseVersion,
    description: description,
    partNumber: partNumber,
    quantity: quantity,
    unit: unit,
    unitCost: unitCost,
    unitPrice: unitPrice,
    notes: notes,
  );

  Future<void> deletePart({
    required String serviceOrderId,
    required String partId,
    int? baseVersion,
  }) => _repo.deletePart(
    orderId: serviceOrderId,
    partId: partId,
    baseVersion: baseVersion,
  );
}

final serviceOrderPartControllerProvider = Provider<ServiceOrderPartController>(
  (ref) => ServiceOrderPartController(ref),
);
