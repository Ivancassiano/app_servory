import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/labels/data/label_template_repository.dart';

import '../../support/stub_dio.dart';

void main() {
  test('LabelTemplate.fromApiJson mapeia o shape', () {
    final t = LabelTemplate.fromApiJson(const {
      'id': 't1',
      'company_id': 'c1',
      'name': 'Padrão',
      'body': 'Linha 1\nLinha 2',
      'version': 3,
    });
    expect(t.id, 't1');
    expect(t.companyId, 'c1');
    expect(t.name, 'Padrão');
    expect(t.body, 'Linha 1\nLinha 2');
    expect(t.version, 3);
  });

  test('create: POST /v1/label-templates com name+body', () async {
    final requests = <String>[];
    final stub = StubDio((req) {
      requests.add('${req.method} ${req.path}');
      if (req.method == 'POST') {
        return (
          status: 201,
          body: {'id': 'new1', 'name': 'M', 'body': 'x', 'version': 1},
        );
      }
      return (status: 200, body: {'label_templates': <dynamic>[]});
    });
    final repo = LabelTemplateRepository(stub.dio);
    addTearDown(repo.dispose);

    final t = await repo.create(name: 'M', body: 'x', companyId: 'co1');
    expect(t.id, 'new1');
    final post = stub.requests.firstWhere((r) => r.method == 'POST');
    expect(post.path, '/v1/label-templates');
    expect((post.data as Map)['name'], 'M');
    expect((post.data as Map)['company_id'], 'co1');
    // create dispara um refresh (GET) em seguida
    expect(requests.any((r) => r == 'GET /v1/label-templates'), isTrue);
  });

  test('update manda version; delete faz DELETE', () async {
    final stub = StubDio((req) {
      if (req.method == 'PATCH') {
        return (status: 200, body: {'id': 't1', 'name': 'M2', 'version': 2});
      }
      if (req.method == 'DELETE') return (status: 204, body: '');
      return (status: 200, body: {'label_templates': <dynamic>[]});
    });
    final repo = LabelTemplateRepository(stub.dio);
    addTearDown(repo.dispose);

    await repo.update(id: 't1', version: 1, name: 'M2', body: 'y');
    final patch = stub.requests.firstWhere((r) => r.method == 'PATCH');
    expect(patch.path, '/v1/label-templates/t1');
    expect((patch.data as Map)['version'], 1);

    await repo.delete('t1');
    expect(
      stub.requests.any(
        (r) => r.method == 'DELETE' && r.path == '/v1/label-templates/t1',
      ),
      isTrue,
    );
  });
}
