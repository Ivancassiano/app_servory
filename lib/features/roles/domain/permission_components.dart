import '../data/roles_api.dart';

/// Nível de acesso de um perfil a um componente do app.
enum ComponentAccess {
  /// Sem nenhuma permissão do componente.
  none,

  /// Só leitura (`recurso.read` + campos de leitura).
  view,

  /// Leitura + criar/editar/remover + ações especiais + campos de escrita.
  edit,

  /// O conjunto de chaves não bate com nenhum dos presets — o usuário mexeu
  /// no "Avançado". Não é selecionável; só um indicador.
  custom,
}

/// Um "componente" do app = um ou mais recursos do catálogo de permissões,
/// agrupado num rótulo que faz sentido pra quem monta o perfil.
class PermComponent {
  const PermComponent(this.id, this.label, this.group, this.resources);

  final String id;
  final String label;
  final String group;
  final List<String> resources;
}

/// Ordem dos grupos na tela.
const permComponentGroups = <String>['Operação', 'Catálogos', 'Administração'];

const permComponents = <PermComponent>[
  // Operação
  PermComponent('clients', 'Clientes', 'Operação', ['client']),
  PermComponent('locations', 'Locais', 'Operação', ['location']),
  PermComponent('items', 'Itens', 'Operação', ['item']),
  PermComponent('service_orders', 'Ordens de serviço', 'Operação', [
    'service_order',
    'service_order_part',
  ]),
  PermComponent('tasks', 'Tarefas', 'Operação', ['task']),
  // Catálogos
  PermComponent('companies', 'Empresas', 'Catálogos', ['company']),
  PermComponent('labels', 'Etiquetas', 'Catálogos', [
    'label',
    'label_batch',
    'label_template',
  ]),
  PermComponent('so_types', 'Tipos de ordem de serviço', 'Catálogos', [
    'service_order_type',
  ]),
  PermComponent('task_types', 'Tipos de tarefa', 'Catálogos', ['task_type']),
  PermComponent('item_types', 'Tipos de item', 'Catálogos', ['item_type']),
  PermComponent('item_fields', 'Campos de item', 'Catálogos', ['item_field']),
  // Administração
  PermComponent('users', 'Usuários', 'Administração', ['user']),
  PermComponent('roles', 'Perfis e permissões', 'Administração', [
    'role',
    'permission_override',
  ]),
  PermComponent('audit', 'Auditoria', 'Administração', ['audit']),
  PermComponent('sessions', 'Sessões e dispositivos', 'Administração', [
    'session',
  ]),
  PermComponent('organization', 'Dados da organização', 'Administração', [
    'organization',
  ]),
];

/// As chaves do catálogo que pertencem a um componente, separadas por papel.
class ComponentKeys {
  ComponentKeys({
    required this.readKeys,
    required this.editKeys,
    required this.specialKeys,
    required this.fieldReadKeys,
    required this.fieldWriteKeys,
    required this.descriptions,
  });

  /// `recurso.read` (não-campo).
  final Set<String> readKeys;

  /// `create` / `update` / `delete` (não-campo).
  final Set<String> editKeys;

  /// Ações que não são CRUD nem leitura (complete, pdf, assign, reserve, …).
  final Set<String> specialKeys;

  final Set<String> fieldReadKeys;
  final Set<String> fieldWriteKeys;

  /// key -> descrição legível (pro "Avançado").
  final Map<String, String> descriptions;

  bool get hasEdit => editKeys.isNotEmpty;
  bool get hasAdvanced =>
      specialKeys.isNotEmpty ||
      fieldReadKeys.isNotEmpty ||
      fieldWriteKeys.isNotEmpty;

  Set<String> get all => {
    ...readKeys,
    ...editKeys,
    ...specialKeys,
    ...fieldReadKeys,
    ...fieldWriteKeys,
  };

  /// O conjunto de chaves para um nível de acesso "limpo" (sem ajuste fino).
  Set<String> keysFor(ComponentAccess access) => switch (access) {
    ComponentAccess.none || ComponentAccess.custom => <String>{},
    ComponentAccess.view => {...readKeys, ...fieldReadKeys},
    ComponentAccess.edit => all,
  };
}

/// Monta o [ComponentKeys] de um componente a partir do catálogo.
ComponentKeys keysOf(
  PermComponent component,
  List<PermissionCatalogEntry> catalog,
) {
  final read = <String>{};
  final edit = <String>{};
  final special = <String>{};
  final fieldRead = <String>{};
  final fieldWrite = <String>{};
  final descriptions = <String, String>{};

  for (final e in catalog) {
    if (!component.resources.contains(e.resource)) continue;
    descriptions[e.key] = e.description;
    if (e.isField) {
      (e.action == 'write' ? fieldWrite : fieldRead).add(e.key);
    } else if (e.action == 'read') {
      read.add(e.key);
    } else if (e.action == 'create' ||
        e.action == 'update' ||
        e.action == 'delete') {
      edit.add(e.key);
    } else {
      special.add(e.key);
    }
  }

  return ComponentKeys(
    readKeys: read,
    editKeys: edit,
    specialKeys: special,
    fieldReadKeys: fieldRead,
    fieldWriteKeys: fieldWrite,
    descriptions: descriptions,
  );
}

/// Deduz o nível de acesso de um perfil a um componente, dado o conjunto de
/// chaves concedidas. `custom` quando não bate exatamente com nenhum preset.
ComponentAccess accessOf(ComponentKeys keys, Set<String> granted) {
  final mine = keys.all.intersection(granted);
  if (mine.isEmpty) return ComponentAccess.none;
  if (!keys.hasEdit) {
    // Componente só-leitura (ex.: auditoria): ter a(s) chave(s) de read => "ver".
    return _sameSet(mine, keys.readKeys)
        ? ComponentAccess.view
        : ComponentAccess.custom;
  }
  if (_sameSet(mine, keys.keysFor(ComponentAccess.edit))) {
    return ComponentAccess.edit;
  }
  if (_sameSet(mine, keys.keysFor(ComponentAccess.view))) {
    return ComponentAccess.view;
  }
  return ComponentAccess.custom;
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
