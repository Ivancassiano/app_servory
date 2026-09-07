import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/person_api.dart';

PersonApi _personApi(Ref ref) =>
    PersonApi(ref.watch(apiClientProvider).businessDio);

/// Dados pessoais do ator. REST puro nas duas plataformas (não sincroniza —
/// é global à conta, não à organização). Alimenta o laudo com o nome e o
/// registro profissional do técnico.
final myPersonProvider = FutureProvider<Person>(
  (ref) => _personApi(ref).getMyPerson(),
);

final personEditControllerProvider = Provider<PersonEditController>(
  (ref) => PersonEditController(ref),
);

class PersonEditController {
  PersonEditController(this._ref);

  final Ref _ref;

  Future<void> save({
    required String fullName,
    required String taxId,
    required String phone,
    required String professionalRegistration,
    required String notes,
  }) async {
    await _personApi(_ref).updateMyPerson(
      fullName: fullName,
      taxId: taxId,
      phone: phone,
      professionalRegistration: professionalRegistration,
      notes: notes,
    );
    _ref.invalidate(myPersonProvider);
  }
}
