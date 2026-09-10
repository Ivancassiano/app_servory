import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/companies/data/company_repository.dart';
import 'package:servory/features/companies/presentation/company_detail_screen.dart';
import 'package:servory/features/reference/data/reference_repository.dart';

class _FakeReferenceRepo implements ReferenceDataRepository {
  @override
  Stream<List<ReferenceItem>> watchList(ReferenceKind kind) =>
      Stream.value(const <ReferenceItem>[]);
  @override
  Future<void> refresh(ReferenceKind kind) async {}
}

Company _company({required String name, int? version}) => Company.fromApiJson({
  'id': 'co1',
  'kind': 'legal',
  'name': name,
  'tax_id': '12.345.678/0001-90',
  'version': version,
});

void main() {
  Widget host(Company company) => ProviderScope(
    overrides: [
      referenceDataRepositoryProvider.overrideWithValue(_FakeReferenceRepo()),
      companyByIdProvider(
        'co1',
      ).overrideWith((ref) => Stream.value(company)),
      companyMembersProvider(
        'co1',
      ).overrideWith((ref) => Stream.value(const <CompanyMember>[])),
    ],
    child: const MaterialApp(home: CompanyDetailScreen(companyId: 'co1')),
  );

  testWidgets('abre em leitura; lápis abre o form; Cancelar volta', (
    tester,
  ) async {
    await tester.pumpWidget(host(_company(name: 'ACME', version: 2)));
    await tester.pumpAndSettle();

    // leitura: sem campos editáveis, tem o lápis
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.text('Pessoa jurídica'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'ACME'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('nova empresa já abre no form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          referenceDataRepositoryProvider.overrideWithValue(
            _FakeReferenceRepo(),
          ),
        ],
        child: const MaterialApp(home: CompanyDetailScreen(companyId: 'new')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nova empresa'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });
}
