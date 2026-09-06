import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/widgets/searchable_list_view.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

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
