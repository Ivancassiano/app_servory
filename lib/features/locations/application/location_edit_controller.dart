import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/location_repository.dart';

/// Fachada fina — a lógica online-first / offline vive no
/// [LocationRepository]. Criar local: Fatia 2.
class LocationEditController {
  LocationEditController(this._ref);
  final Ref _ref;

  Future<void> update({
    required String locationId,
    int? baseVersion,
    required String name,
    required String contactPerson,
    required String phone,
    required String notes,
  }) => _ref.read(locationRepositoryProvider).update(
    id: locationId,
    baseVersion: baseVersion,
    name: name,
    contactPerson: contactPerson,
    phone: phone,
    notes: notes,
  );
}

final locationEditControllerProvider = Provider<LocationEditController>(
  (ref) => LocationEditController(ref),
);
