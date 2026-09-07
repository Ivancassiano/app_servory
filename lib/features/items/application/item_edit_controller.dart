import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/item_repository.dart';

/// Fachada fina — a lógica online-first / offline vive no [ItemRepository].
class ItemEditController {
  ItemEditController(this._ref);
  final Ref _ref;

  Future<String> create({
    required String clientId,
    String? parentItemId,
    required ItemFields fields,
  }) => _ref
      .read(itemRepositoryProvider)
      .create(clientId: clientId, parentItemId: parentItemId, fields: fields);

  Future<void> update({
    required String itemId,
    int? baseVersion,
    required ItemFields fields,
  }) => _ref
      .read(itemRepositoryProvider)
      .update(id: itemId, baseVersion: baseVersion, fields: fields);

  Future<void> reparent({
    required String itemId,
    int? baseVersion,
    String? parentItemId,
  }) => _ref
      .read(itemRepositoryProvider)
      .reparent(
        id: itemId,
        baseVersion: baseVersion,
        parentItemId: parentItemId,
      );
}

final itemEditControllerProvider = Provider<ItemEditController>(
  (ref) => ItemEditController(ref),
);
