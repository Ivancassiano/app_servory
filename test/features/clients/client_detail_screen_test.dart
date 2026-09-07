import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servory/core/db/app_database.dart';
import 'package:servory/core/network/api_exception.dart';
import 'package:servory/features/clients/data/client_mapper.dart';
import 'package:servory/features/clients/data/client_repository.dart';
import 'package:servory/features/clients/presentation/client_detail_screen.dart';
import 'package:servory/features/contacts/data/contact_repository.dart';
import 'package:servory/features/labels/data/qr_mapper.dart';
import 'package:servory/features/labels/data/qr_repository.dart';

LocalClient _client({required String name, int? version}) => clientFromApiJson({
  'id': 'c1',
  'kind': 'legal',
  'name': name,
  'phone': '11999',
  'version': ?version,
}, organizationId: 'org1');

/// Repositório falso: guarda um cliente em memória; `update` estoura
/// `VERSION_CONFLICT` na 1ª vez e, ao mesmo tempo, simula a alteração feita
/// por outra pessoa (novo nome + versão).
class _FakeClientRepo implements ClientRepository {
  _FakeClientRepo(this._current);
  LocalClient _current;
  int _updateCalls = 0;

  @override
  Stream<List<LocalClient>> watchList() => Stream.value([_current]);

  @override
  Stream<LocalClient?> watchById(String id) => Stream.value(_current);

  @override
  Future<void> refresh() async {}

  @override
  Future<String> create({
    required String kind,
    required String name,
    required String phone,
  }) async => 'c1';

  @override
  Future<void> update({
    required String id,
    required int? baseVersion,
    required String name,
    required String phone,
  }) async {
    _updateCalls++;
    if (_updateCalls == 1) {
      _current = _client(name: 'Nome do servidor', version: 2);
      throw const ApiException(code: 'VERSION_CONFLICT', message: 'conflito');
    }
  }
}

void main() {
  Widget host(_FakeClientRepo repo) => ProviderScope(
    overrides: [
      clientRepositoryProvider.overrideWithValue(repo),
      contactsProvider.overrideWith(
        (ref, ContactKey key) => Stream.value(const <Contact>[]),
      ),
      activeQrCodeProvider.overrideWith(
        (ref, QrTarget target) => Stream.value(null),
      ),
    ],
    child: const MaterialApp(home: ClientDetailScreen(clientId: 'c1')),
  );

  testWidgets('conflito de versão mostra o aviso e recarrega do servidor', (
    tester,
  ) async {
    final repo = _FakeClientRepo(_client(name: 'Nome antigo', version: 1));
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();

    // formulário semeado com o nome atual
    expect(find.widgetWithText(TextFormField, 'Nome antigo'), findsOneWidget);

    // edita e tenta salvar -> conflito
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome antigo'),
      'Minha edição',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Outra pessoa alterou este registro enquanto você editava.'),
      findsOneWidget,
    );

    // recarrega -> re-semeia com o dado do servidor, aviso some
    await tester.tap(find.widgetWithText(OutlinedButton, 'Recarregar do servidor'));
    await tester.pumpAndSettle();

    expect(
      find.text('Outra pessoa alterou este registro enquanto você editava.'),
      findsNothing,
    );
    expect(find.widgetWithText(TextFormField, 'Nome do servidor'), findsOneWidget);
  });
}
