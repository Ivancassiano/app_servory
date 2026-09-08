import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/item_repository.dart';

/// Fachada fina — a lógica online-first / offline vive no [ItemRepository].
class ItemEditController {
  ItemEditController(this._ref);
  final Ref _ref;

  Future<String> create({
    required String clientId,
    required ItemFields fields,
  }) => _ref
      .read(itemRepositoryProvider)
      .create(clientId: clientId, fields: fields);

  Future<void> update({
    required String itemId,
    int? baseVersion,
    required ItemFields fields,
  }) => _ref
      .read(itemRepositoryProvider)
      .update(id: itemId, baseVersion: baseVersion, fields: fields);
}

final itemEditControllerProvider = Provider<ItemEditController>(
  (ref) => ItemEditController(ref),
);
