import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/equipment_repository.dart';

/// Fachada fina — lógica online-first / offline no [EquipmentRepository].
/// Criar equipamento: Fatia 2. `serial_number`/`cost` ficam fora do
/// formulário (campos sensíveis, sem checagem de permissão de escrita).
class EquipmentEditController {
  EquipmentEditController(this._ref);
  final Ref _ref;

  Future<String> create({
    required String locationId,
    required String equipmentTypeId,
    required String name,
    required String brand,
    required String model,
    required String notes,
  }) => _ref.read(equipmentRepositoryProvider).create(
    locationId: locationId,
    equipmentTypeId: equipmentTypeId,
    name: name,
    brand: brand,
    model: model,
    notes: notes,
  );

  Future<void> update({
    required String equipmentId,
    int? baseVersion,
    required String name,
    required String brand,
    required String model,
    required String notes,
  }) => _ref.read(equipmentRepositoryProvider).update(
    id: equipmentId,
    baseVersion: baseVersion,
    name: name,
    brand: brand,
    model: model,
    notes: notes,
  );
}

final equipmentEditControllerProvider = Provider<EquipmentEditController>(
  (ref) => EquipmentEditController(ref),
);
