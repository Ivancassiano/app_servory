import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/paged_source.dart';
import '../../../core/db/app_database.dart';
import '../data/item_repository.dart';

export '../data/item_repository.dart' show ItemFields, itemRepositoryProvider;
export '../data/item_type_repository.dart'
    show itemTypeListProvider, itemTypeRepositoryProvider;
export '../data/item_field_def_repository.dart'
    show
        itemFieldDefListProvider,
        itemFieldDefRepositoryProvider,
        itemFieldDefsForTypeProvider,
        itemFieldOptionsProvider;
export '../data/item_field_value_repository.dart'
    show
        TypedFieldValue,
        itemFieldValueRepositoryProvider,
        itemFieldValuesProvider;

/// Delegam ao [itemRepositoryProvider] (drift no app, REST no web).
final itemListProvider = StreamProvider<List<LocalItem>>(
  (ref) => ref.watch(itemRepositoryProvider).watchList(),
);

/// Fonte paginada da lista (só web) — nula nos apps.
final itemListPagingProvider = Provider<PagedSource?>(
  (ref) => pagingOf(ref.watch(itemRepositoryProvider)),
);

final itemByIdProvider = StreamProvider.family<LocalItem?, String>(
  (ref, id) => ref.watch(itemRepositoryProvider).watchById(id),
);

/// Itens de um cliente (derivado da lista completa).
final itemsByClientProvider = Provider.family<List<LocalItem>, String>((
  ref,
  clientId,
) {
  final all = ref.watch(itemListProvider).value ?? const [];
  return [
    for (final i in all)
      if (i.clientId == clientId) i,
  ];
});

/// Filhos diretos de um item.
final itemsByParentProvider = Provider.family<List<LocalItem>, String>((
  ref,
  parentId,
) {
  final all = ref.watch(itemListProvider).value ?? const [];
  return [
    for (final i in all)
      if (i.parentItemId == parentId) i,
  ];
});
