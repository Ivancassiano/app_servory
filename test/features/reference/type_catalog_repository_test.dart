import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/reference/data/type_catalog_repository.dart';

import '../../support/stub_dio.dart';

void main() {
  test('TypeCatalogItem.fromApiJson mapeia o shape', () {
    final t = TypeCatalogItem.fromApiJson(const {
      'id': 'et1',
      'name': 'Compressor',
      'description': 'Ar comprimido',
      'version': 2,
    });
    expect(t.id, 'et1');
    expect(t.name, 'Compressor');
    expect(t.description, 'Ar comprimido');
    expect(t.version, 2);
  });

  test('refresh lê a lista pela chave do tipo e ordena por nome', () async {
    final stub = StubDio((req) {
      if (req.path == '/v1/equipment-types') {
        return (
          status: 200,
          body: {
            'equipment_types': [
              {'id': 'b', 'name': 'Bomba', 'description': '', 'version': 1},
              {'id': 'a', 'name': 'Ar-condicionado', 'description': '', 'version': 1},
            ],
          },
        );
      }
      return (status: 200, body: {'equipment_types': <dynamic>[]});
    });
    final repo = TypeCatalogRepository(stub.dio);
    addTearDown(repo.dispose);

    final items = await repo.watchList(TypeCatalog.equipmentType).firstWhere(
      (l) => l.isNotEmpty,
    );
    expect(items.map((e) => e.name), ['Ar-condicionado', 'Bomba']);
  });

  test('create: POST no path do tipo, depois refresh (GET)', () async {
    final seen = <String>[];
    final stub = StubDio((req) {
      seen.add('${req.method} ${req.path}');
      if (req.method == 'POST') {
        return (
          status: 201,
          body: {'id': 'so1', 'name': 'Preventiva', 'description': '', 'version': 1},
        );
      }
      return (status: 200, body: {'service_order_types': <dynamic>[]});
    });
    final repo = TypeCatalogRepository(stub.dio);
    addTearDown(repo.dispose);

    await repo.create(TypeCatalog.serviceOrderType, name: 'Preventiva');
    final post = stub.requests.firstWhere((r) => r.method == 'POST');
    expect(post.path, '/v1/service-order-types');
    expect((post.data as Map)['name'], 'Preventiva');
    expect(seen.contains('GET /v1/service-order-types'), isTrue);
  });

  test('update manda version no corpo; delete faz DELETE no path do tipo', () async {
    final stub = StubDio((req) {
      if (req.method == 'PATCH') {
        return (status: 200, body: {'id': 'et1', 'name': 'X', 'version': 3});
      }
      if (req.method == 'DELETE') return (status: 204, body: '');
      return (status: 200, body: {'equipment_types': <dynamic>[]});
    });
    final repo = TypeCatalogRepository(stub.dio);
    addTearDown(repo.dispose);

    await repo.update(
      TypeCatalog.equipmentType,
      'et1',
      version: 2,
      name: 'X',
      description: 'y',
    );
    final patch = stub.requests.firstWhere((r) => r.method == 'PATCH');
    expect(patch.path, '/v1/equipment-types/et1');
    expect((patch.data as Map)['version'], 2);

    await repo.delete(TypeCatalog.equipmentType, 'et1');
    expect(
      stub.requests.any(
        (r) => r.method == 'DELETE' && r.path == '/v1/equipment-types/et1',
      ),
      isTrue,
    );
  });
}
