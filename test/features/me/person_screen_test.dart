import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/me/application/person_provider.dart';
import 'package:servory/features/me/data/person_api.dart';
import 'package:servory/features/me/presentation/person_screen.dart';

class _FakePersonEdit implements PersonEditController {
  Map<String, String>? saved;

  @override
  Future<void> save({
    required String fullName,
    required String taxId,
    required String phone,
    required String professionalRegistration,
    required String notes,
  }) async {
    saved = {
      'fullName': fullName,
      'taxId': taxId,
      'phone': phone,
      'registration': professionalRegistration,
      'notes': notes,
    };
  }
}

void main() {
  const person = Person(
    fullName: 'Ana Técnica',
    taxId: '111',
    phone: '9999',
    professionalRegistration: 'CREA-SP 1',
    notes: '',
  );

  Widget host(_FakePersonEdit edit) => ProviderScope(
    overrides: [
      myPersonProvider.overrideWith((ref) async => person),
      personEditControllerProvider.overrideWithValue(edit),
    ],
    child: const MaterialApp(home: PersonScreen()),
  );

  testWidgets('semeia o formulário e salva os campos', (tester) async {
    final edit = _FakePersonEdit();
    await tester.pumpWidget(host(edit));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Ana Técnica'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'CREA-SP 1'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'CREA-SP 1'),
      'CREA-SP 2',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(edit.saved?['registration'], 'CREA-SP 2');
    expect(edit.saved?['fullName'], 'Ana Técnica');
  });

  testWidgets('nome vazio bloqueia o salvar', (tester) async {
    final edit = _FakePersonEdit();
    await tester.pumpWidget(host(edit));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ana Técnica'),
      '',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pump();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(edit.saved, isNull);
  });
}
