import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/location_repository.dart';

/// Fachada fina — a lógica online-first / offline vive no [LocationRepository].
class LocationEditController {
  LocationEditController(this._ref);
  final Ref _ref;

  Future<String> create({
    required String clientId,
    required LocationFields fields,
  }) => _ref
      .read(locationRepositoryProvider)
      .create(clientId: clientId, fields: fields);

  Future<void> update({
    required String locationId,
    int? baseVersion,
    required LocationFields fields,
  }) => _ref
      .read(locationRepositoryProvider)
      .update(id: locationId, baseVersion: baseVersion, fields: fields);

  Future<void> delete({required String locationId, int? baseVersion}) => _ref
      .read(locationRepositoryProvider)
      .delete(id: locationId, baseVersion: baseVersion);
}

final locationEditControllerProvider = Provider<LocationEditController>(
  (ref) => LocationEditController(ref),
);
