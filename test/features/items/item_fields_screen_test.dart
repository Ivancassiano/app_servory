import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/features/items/application/items_provider.dart';
import 'package:servory/features/items/data/item_field_def_repository.dart';
import 'package:servory/features/items/data/item_type_repository.dart';
import 'package:servory/features/items/presentation/item_fields_screen.dart';

final _now = DateTime(2026, 9, 20);

class _FakeItemTypeRepository implements ItemTypeRepository {
  @override
  Stream<List<LocalItemType>> watchList() => Stream.value(const []);
  @override
  Future<void> refresh() async {}
}

LocalItemFieldDef _colorDef() => LocalItemFieldDef(
  id: 'd1',
  organizationId: 'org',
  label: 'Cor',
  fieldKey: 'cor',
  dataType: 'select',
  required: false,
  position: 0,
  cachedAt: _now,
);

LocalItemFieldOption _opt(String id, String label, {bool active = true}) =>
    LocalItemFieldOption(
      id: id,
      organizationId: 'org',
      fieldDefId: 'd1',
      label: label,
      value: id,
      position: 0,
      isActive: active,
      cachedAt: _now,
    );

/// Repositório falso: `watchDefs`/`watchOptions` alimentam a tela direto (sem
/// banco real), e `update` grava o que foi enviado para o teste conferir.
class _FakeItemFieldDefRepository extends ItemFieldDefRepository {
  _FakeItemFieldDefRepository(super.ref, this._def, this._options);

  final LocalItemFieldDef _def;
  final List<LocalItemFieldOption> _options;
  final updateCalls = <({String label, List<FieldOptionInput> options})>[];

  @override
  Stream<List<LocalItemFieldDef>> watchDefs() => Stream.value([_def]);

  @override
  Stream<Map<String, List<LocalItemFieldOption>>> watchAllOptions() =>
      Stream.value({_def.id: _options});

  @override
  Stream<List<LocalItemFieldOption>> watchOptions(String fieldDefId) =>
      Stream.value(_options);

  @override
  Future<void> refresh() async {}

  @override
  Future<void> create({
    String? itemTypeId,
    required String label,
    required String dataType,
    required bool required,
    int position = 0,
    List<FieldOptionInput> options = const [],
  }) async {}

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    String? itemTypeId,
    required String label,
    required String dataType,
    required bool required,
    int position = 0,
    List<FieldOptionInput> options = const [],
  }) async {
    updateCalls.add((label: label, options: options));
  }

  @override
  Future<void> delete(String id) async {}
}

void main() {
  // Regressão de dois bugs achados testando no emulador (2026-09-20):
  //
  // 1. Editar um campo lista logo após criá-lo (provider de opções "frio",
  //    nunca observado antes) mostrava a lista de opções VAZIA mesmo com dados
  //    salvos — `_edit` lia `ref.read(itemFieldOptionsProvider(id)).value`
  //    antes do stream emitir. Corrigido lendo com
  //    `await repo.watchOptions(id).first`.
  // 2. Salvar nesse formulário (StatefulBuilder + controllers descartados
  //    manualmente após o `Navigator.pop`) derrubava a tela com
  //    "_dependents.isEmpty": o TextField ainda estava montado terminando a
  //    animação de fechar quando o controller já tinha sido descartado.
  //    Corrigido com `_FieldFormSheet`, um StatefulWidget próprio cujo
  //    `dispose()` só roda quando o framework garante que é seguro.
  testWidgets(
    'editar campo lista: opções pré-existentes aparecem e inativar+salvar '
    'não derruba a tela',
    (tester) async {
      // Instância capturada pelo `overrideWith` — evita fabricar um `Ref`
      // falso, o próprio Riverpod fornece um de verdade ao construir.
      late _FakeItemFieldDefRepository repo;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemTypeRepositoryProvider.overrideWithValue(
              _FakeItemTypeRepository(),
            ),
            itemFieldDefRepositoryProvider.overrideWith((ref) {
              repo = _FakeItemFieldDefRepository(ref, _colorDef(), [
                _opt('o1', 'Azul'),
                _opt('o2', 'Verde'),
              ]);
              return repo;
            }),
          ],
          child: const MaterialApp(home: ItemFieldsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cor'));
      await tester.pumpAndSettle();

      // As duas opções já salvas aparecem — não fica em branco.
      expect(find.text('Azul'), findsOneWidget);
      expect(find.text('Verde'), findsOneWidget);

      // "Inativar" a primeira linha (Azul).
      await tester.tap(find.byTooltip('Inativar').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Sem crash: a tela fechou a folha e voltou pra lista.
      expect(tester.takeException(), isNull);
      expect(find.text('Editar campo'), findsNothing);

      expect(repo.updateCalls, hasLength(1));
      final sent = repo.updateCalls.single.options;
      expect(sent.firstWhere((o) => o.id == 'o1').active, isFalse);
      expect(sent.firstWhere((o) => o.id == 'o2').active, isTrue);
    },
  );
}
