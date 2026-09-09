import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/roles_api.dart';

/// Catálogo global de permissões — estático na prática; sem autoDispose.
final permissionCatalogProvider = FutureProvider<List<PermissionCatalogEntry>>(
  (ref) => ref.watch(rolesApiProvider).listCatalog(),
);

final rolesProvider = FutureProvider.autoDispose<List<Role>>(
  (ref) => ref.watch(rolesApiProvider).listRoles(),
);

final roleByIdProvider = FutureProvider.autoDispose.family<Role, String>(
  (ref, id) => ref.watch(rolesApiProvider).getRole(id),
);

class RolesController {
  RolesController(this._ref);

  final Ref _ref;

  RolesApi get _api => _ref.read(rolesApiProvider);

  void _refresh([String? id]) {
    _ref.invalidate(rolesProvider);
    if (id != null) _ref.invalidate(roleByIdProvider(id));
  }

  Future<Role> create({
    required String name,
    required String description,
    Set<String> allowKeys = const {},
  }) async {
    final role = await _api.createRole(
      key: _slugKey(name),
      name: name,
      description: description,
    );
    if (allowKeys.isNotEmpty) {
      await _api.setRolePermissions(role.id, allowKeys);
    }
    _refresh(role.id);
    return role;
  }

  Future<void> saveInfo(
    String id, {
    required String name,
    required String description,
  }) async {
    await _api.updateRole(id, name: name, description: description);
    _refresh(id);
  }

  Future<void> savePermissions(String id, Set<String> allowKeys) async {
    await _api.setRolePermissions(id, allowKeys);
    _refresh(id);
  }

  Future<void> delete(String id) async {
    await _api.deleteRole(id);
    _refresh();
  }

  /// A `key` do perfil é um identificador técnico que o usuário nunca vê —
  /// derivamos do nome e deixamos único com um sufixo curto de tempo.
  static String _slugKey(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return '${base.isEmpty ? 'perfil' : base}_$suffix';
  }
}

final rolesControllerProvider = Provider<RolesController>(RolesController.new);
