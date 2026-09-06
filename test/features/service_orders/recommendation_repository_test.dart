import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/network/api_client.dart';
import 'package:servory/core/providers.dart';
import 'package:servory/features/service_orders/data/recommendation_repository.dart';

import '../../support/stub_dio.dart';

void main() {
  test('Recommendation.fromApiJson mapeia o shape', () {
    final r = Recommendation.fromApiJson(const {
      'id': 'r1',
      'description': 'Trocar correia',
      'priority': 'high',
      'status': 'open',
      'notes': 'antes de 90 dias',
      'version': 2,
    });
    expect(r.id, 'r1');
    expect(r.priority, 'high');
    expect(r.notes, 'antes de 90 dias');
    expect(r.version, 2);
  });

  test('add: POST em .../recommendations com description', () async {
    final stub = StubDio((req) {
      if (req.method == 'POST') {
        return (
          status: 201,
          body: {
            'id': 'r9',
            'description': 'X',
            'priority': 'medium',
            'status': 'open',
            'version': 1,
          },
        );
      }
      return (status: 200, body: {'recommendations': <dynamic>[]});
    });
    final c = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
      ],
    );
    addTearDown(c.dispose);

    await c.read(recommendationRepositoryProvider).add('so1', description: 'X');
    final post = stub.requests.firstWhere((r) => r.method == 'POST');
    expect(post.path, '/v1/service-orders/so1/recommendations');
    expect((post.data as Map)['description'], 'X');
  });

  test('update manda version; delete faz DELETE no recId', () async {
    final stub = StubDio((req) {
      if (req.method == 'PATCH') {
        return (status: 200, body: {'id': 'r1', 'description': 'Y', 'version': 3});
      }
      if (req.method == 'DELETE') return (status: 204, body: '');
      return (status: 200, body: {'recommendations': <dynamic>[]});
    });
    final c = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(_FakeApiClient(stub.dio)),
      ],
    );
    addTearDown(c.dispose);
    final repo = c.read(recommendationRepositoryProvider);

    await repo.update(
      'so1',
      'r1',
      version: 2,
      description: 'Y',
      priority: 'low',
      status: 'addressed',
      notes: '',
    );
    final patch = stub.requests.firstWhere((r) => r.method == 'PATCH');
    expect(patch.path, '/v1/service-orders/so1/recommendations/r1');
    expect((patch.data as Map)['version'], 2);

    await repo.delete('so1', 'r1');
    expect(
      stub.requests.any(
        (r) =>
            r.method == 'DELETE' &&
            r.path == '/v1/service-orders/so1/recommendations/r1',
      ),
      isTrue,
    );
  });
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.businessDio);
  @override
  final Dio businessDio;
  @override
  Dio get authDio => businessDio;
}
