import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/client_repository.dart';

/// Fachada fina para a tela de cadastro. A lógica online-first / offline
/// vive no [ClientRepository]; `kind` só existe na criação (imutável,
/// spec §7.3).
class ClientEditController {
  ClientEditController(this._ref);
  final Ref _ref;

  ClientRepository get _repo => _ref.read(clientRepositoryProvider);

  Future<String> create({
    required String kind,
    required String name,
    required String phone,
  }) => _repo.create(kind: kind, name: name, phone: phone);

  Future<void> update({
    required String clientId,
    int? baseVersion,
    required String name,
    required String phone,
  }) => _repo.update(
    id: clientId,
    baseVersion: baseVersion,
    name: name,
    phone: phone,
  );
}

final clientEditControllerProvider = Provider<ClientEditController>(
  (ref) => ClientEditController(ref),
);
