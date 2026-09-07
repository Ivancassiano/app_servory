import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/widgets/conflict_notice.dart';

void main() {
  testWidgets('mostra o texto e dispara onReload no botão', (tester) async {
    var reloads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConflictNotice(onReload: () => reloads++),
        ),
      ),
    );

    expect(
      find.text('Outra pessoa alterou este registro enquanto você editava.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Recarregar do servidor'));
    expect(reloads, 1);
  });

  testWidgets('reloading desabilita o botão e mostra progresso', (tester) async {
    var reloads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConflictNotice(onReload: () => reloads++, reloading: true),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton));
    expect(reloads, 0);
  });
}
