import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/data/remote_collection.dart';

import '../../support/stub_dio.dart';

/// 45 itens no "servidor", páginas de 20.
StubDio _server() => StubDio((req) {
  final page = int.tryParse('${req.queryParameters['page'] ?? 1}') ?? 1;
  final size = int.tryParse('${req.queryParameters['size'] ?? 20}') ?? 20;
  const total = 45;
  final start = (page - 1) * size;
  final items = [
    for (var i = start; i < start + size && i < total; i++)
      {'id': 'item-$i', 'name': 'Item $i'},
  ];
  return (status: 200, body: {'items': items, 'total': total});
});

RemoteCollection<String> _collection(StubDio stub) => RemoteCollection<String>(
  dio: stub.dio,
  listPath: '/v1/things',
  listKey: 'items',
  fromJson: (j) => j['id'] as String,
  idOf: (s) => s,
  pageSize: 20,
);

void main() {
  test('refresh carrega a 1ª página e sinaliza hasMore', () async {
    final c = _collection(_server());
    addTearDown(c.dispose);

    final first = await c.watchList().first;
    expect(first, hasLength(20));
    expect(c.hasMore, isTrue);
    expect(c.isLoadingMore, isFalse);
  });

  test('loadMore anexa a próxima página', () async {
    final c = _collection(_server());
    addTearDown(c.dispose);

    await c.refresh();
    await c.loadMore();
    expect(c.hasMore, isTrue); // 40 de 45

    await c.loadMore();
    expect(c.hasMore, isFalse); // 45 de 45
  });

  test('loadAll esgota as páginas', () async {
    final stub = _server();
    final c = _collection(stub);
    addTearDown(c.dispose);

    await c.refresh();
    await c.loadAll();

    final all = await c.watchList().first;
    expect(all, hasLength(45));
    expect(c.hasMore, isFalse);
    // 1 refresh + 2 loadMore (páginas 2 e 3)
    expect(stub.requests.map((r) => r.queryParameters['page']), [1, 2, 3]);
  });

  test('sem pageSize continua em modo único (sem hasMore)', () async {
    final stub = StubDio(
      (req) => (status: 200, body: {'items': <dynamic>[], 'total': 99}),
    );
    final c = RemoteCollection<String>(
      dio: stub.dio,
      listPath: '/v1/things',
      listKey: 'items',
      fromJson: (j) => j['id'] as String,
      idOf: (s) => s,
    );
    addTearDown(c.dispose);
    await c.refresh();
    expect(c.hasMore, isFalse);
    await c.loadMore(); // no-op
    expect(stub.requests, hasLength(1));
  });
}
