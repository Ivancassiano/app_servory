import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/roles/data/roles_api.dart';
import 'package:servory/features/roles/domain/permission_components.dart';

PermissionCatalogEntry _e(
  String key,
  String resource,
  String action, {
  bool field = false,
}) => PermissionCatalogEntry(
  key: key,
  resource: resource,
  action: action,
  isField: field,
  description: key,
);

// Um catálogo mínimo cobrindo os formatos que importam.
final _catalog = <PermissionCatalogEntry>[
  _e('client.read', 'client', 'read'),
  _e('client.create', 'client', 'create'),
  _e('client.update', 'client', 'update'),
  _e('client.delete', 'client', 'delete'),
  _e('client.name.read', 'client', 'read', field: true),
  _e('client.name.write', 'client', 'write', field: true),
  _e('client.internal_notes.read', 'client', 'read', field: true),
  _e('service_order.read', 'service_order', 'read'),
  _e('service_order.create', 'service_order', 'create'),
  _e('service_order.update', 'service_order', 'update'),
  _e('service_order.complete', 'service_order', 'complete'),
  _e('service_order.pdf', 'service_order', 'pdf'),
  _e('service_order_part.read', 'service_order_part', 'read'),
  _e('service_order_part.create', 'service_order_part', 'create'),
  _e('audit.read', 'audit', 'read'),
];

PermComponent _c(String id) => permComponents.firstWhere((c) => c.id == id);

void main() {
  test('keysOf separa coarse / especial / campo', () {
    final k = keysOf(_c('clients'), _catalog);
    expect(k.readKeys, {'client.read'});
    expect(k.editKeys, {'client.create', 'client.update', 'client.delete'});
    expect(k.specialKeys, isEmpty);
    expect(k.fieldReadKeys, {'client.name.read', 'client.internal_notes.read'});
    expect(k.fieldWriteKeys, {'client.name.write'});
    expect(k.hasEdit, isTrue);
    expect(k.hasAdvanced, isTrue);
  });

  test('ordem de serviço agrupa o recurso de peças e as ações especiais', () {
    final k = keysOf(_c('service_orders'), _catalog);
    expect(k.readKeys, {'service_order.read', 'service_order_part.read'});
    expect(k.editKeys, {
      'service_order.create',
      'service_order.update',
      'service_order_part.create',
    });
    expect(k.specialKeys, {'service_order.complete', 'service_order.pdf'});
  });

  group('accessOf', () {
    final k = keysOf(_c('clients'), _catalog);

    test('vazio => none', () {
      expect(accessOf(k, {}), ComponentAccess.none);
    });

    test('só as leituras => view', () {
      expect(
        accessOf(k, {
          'client.read',
          'client.name.read',
          'client.internal_notes.read',
        }),
        ComponentAccess.view,
      );
    });

    test('tudo => edit', () {
      expect(accessOf(k, k.all), ComponentAccess.edit);
    });

    test('leitura + um write avulso => custom', () {
      expect(
        accessOf(k, {'client.read', 'client.name.write'}),
        ComponentAccess.custom,
      );
    });

    test('read sem os campos => custom (não é o preset "view")', () {
      expect(accessOf(k, {'client.read'}), ComponentAccess.custom);
    });
  });

  test('componente só-leitura (auditoria): none/view, sem edit', () {
    final k = keysOf(_c('audit'), _catalog);
    expect(k.hasEdit, isFalse);
    expect(accessOf(k, {}), ComponentAccess.none);
    expect(accessOf(k, {'audit.read'}), ComponentAccess.view);
  });

  test('keysFor(edit) inclui campos e ações especiais', () {
    final k = keysOf(_c('service_orders'), _catalog);
    final edit = k.keysFor(ComponentAccess.edit);
    expect(edit, contains('service_order.complete'));
    expect(edit, contains('service_order.pdf'));
    expect(edit, contains('service_order_part.create'));
    expect(k.keysFor(ComponentAccess.none), isEmpty);
  });

  test('todo componente da tela existe no grupo declarado', () {
    for (final c in permComponents) {
      expect(permComponentGroups, contains(c.group));
    }
  });
}
