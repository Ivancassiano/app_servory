import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/paged_source.dart';
import '../../../core/db/app_database.dart';
import '../data/client_repository.dart';

export '../data/client_repository.dart' show clientRepositoryProvider;

/// Fonte paginada da lista (só web) — nula nos apps, que leem tudo do drift.
/// A tela de lista passa isto ao [SearchableListView].
final clientListPagingProvider = Provider<PagedSource?>(
  (ref) => pagingOf(ref.watch(clientRepositoryProvider)),
);

/// Lista/detalhe de clientes — delegam ao [clientRepositoryProvider], que no
/// app lê do cache drift (`.watch()` reativo) e no web do cache REST em
/// memória. Os dois expõem o mesmo `Stream`, então as telas não mudam.
final clientListProvider = StreamProvider<List<LocalClient>>(
  (ref) => ref.watch(clientRepositoryProvider).watchList(),
);

final clientByIdProvider = StreamProvider.family<LocalClient?, String>(
  (ref, id) => ref.watch(clientRepositoryProvider).watchById(id),
);
