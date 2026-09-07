import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/data/paged_source.dart';
import 'package:servory/core/widgets/searchable_list_view.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

/// [PagedSource] falso: [hasMore] enquanto ainda há páginas; conta as
/// chamadas de [loadMore]/[loadAll].
class FakePaged extends ChangeNotifier implements PagedSource {
  FakePaged({this.pages = 2});
  int pages;
  int loadMoreCalls = 0;
  int loadAllCalls = 0;

  @override
  bool get hasMore => pages > 1;

  @override
  bool get isLoadingMore => false;

  @override
  Future<void> loadMore() async {
    loadMoreCalls++;
    if (pages > 1) pages--;
    notifyListeners();
  }

  @override
  Future<void> loadAll() async {
    loadAllCalls++;
    pages = 1;
    notifyListeners();
  }
}

void main() {
  testWidgets('filtra pela busca, ignorando acento e caixa', (tester) async {
    await tester.pumpWidget(
      _host(
        SearchableListView<String>(
          async: const AsyncData(['São Paulo', 'Santos', 'Campinas']),
          onRefresh: () async {},
          hintText: 'Buscar',
          emptyMessage: 'vazio',
          searchText: (s) => s,
          itemBuilder: (_, s) => ListTile(title: Text(s)),
        ),
      ),
    );

    expect(find.text('São Paulo'), findsOneWidget);
    expect(find.text('Santos'), findsOneWidget);
    expect(find.text('Campinas'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'sao');
    await tester.pumpAndSettle();

    expect(find.text('São Paulo'), findsOneWidget);
    expect(find.text('Santos'), findsNothing);
    expect(find.text('Campinas'), findsNothing);
  });

  testWidgets('vários termos: todos precisam bater', (tester) async {
    await tester.pumpWidget(
      _host(
        SearchableListView<String>(
          async: const AsyncData(['Padaria Central', 'Padaria Sul', 'Bar Norte']),
          onRefresh: () async {},
          hintText: 'Buscar',
          emptyMessage: 'vazio',
          searchText: (s) => s,
          itemBuilder: (_, s) => ListTile(title: Text(s)),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'padaria sul');
    await tester.pumpAndSettle();

    expect(find.text('Padaria Sul'), findsOneWidget);
    expect(find.text('Padaria Central'), findsNothing);
  });

  testWidgets('sem resultado mostra "Nenhum resultado."', (tester) async {
    await tester.pumpWidget(
      _host(
        SearchableListView<String>(
          async: const AsyncData(['Alfa', 'Beta']),
          onRefresh: () async {},
          hintText: 'Buscar',
          emptyMessage: 'nada cadastrado',
          searchText: (s) => s,
          itemBuilder: (_, s) => ListTile(title: Text(s)),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nenhum resultado.'), findsOneWidget);
  });

  testWidgets('lista vazia mostra a emptyMessage', (tester) async {
    await tester.pumpWidget(
      _host(
        SearchableListView<String>(
          async: const AsyncData([]),
          onRefresh: () async {},
          hintText: 'Buscar',
          emptyMessage: 'nada cadastrado',
          searchText: (s) => s,
          itemBuilder: (_, s) => ListTile(title: Text(s)),
        ),
      ),
    );
    expect(find.text('nada cadastrado'), findsOneWidget);
  });

  testWidgets('paging: rodapé some ao esgotar; busca dispara loadAll', (
    tester,
  ) async {
    final paged = FakePaged(pages: 3);
    await tester.pumpWidget(
      _host(
        SearchableListView<String>(
          async: const AsyncData(['Alfa', 'Beta']),
          onRefresh: () async {},
          hintText: 'Buscar',
          emptyMessage: 'vazio',
          searchText: (s) => s,
          paging: paged,
          itemBuilder: (_, s) => ListTile(title: Text(s)),
        ),
      ),
    );

    // rodapé de carregamento visível enquanto hasMore
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // digitar puxa tudo (busca client-side precisa da lista completa)
    await tester.enterText(find.byType(TextField), 'alfa');
    await tester.pumpAndSettle();
    expect(paged.loadAllCalls, 1);

    // limpar a busca: sem mais páginas, sem rodapé
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('extraFilter é aplicado antes da busca', (tester) async {
    await tester.pumpWidget(
      _host(
        SearchableListView<int>(
          async: const AsyncData([1, 2, 3, 4]),
          onRefresh: () async {},
          hintText: 'Buscar',
          emptyMessage: 'vazio',
          searchText: (n) => '$n',
          extraFilter: (n) => n.isEven,
          itemBuilder: (_, n) => ListTile(title: Text('n$n')),
        ),
      ),
    );
    expect(find.text('n2'), findsOneWidget);
    expect(find.text('n4'), findsOneWidget);
    expect(find.text('n1'), findsNothing);
    expect(find.text('n3'), findsNothing);
  });
}
