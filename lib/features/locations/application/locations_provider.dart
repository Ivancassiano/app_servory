import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/paged_source.dart';
import '../../../core/db/app_database.dart';
import '../data/location_repository.dart';

export '../data/location_repository.dart' show locationRepositoryProvider;

/// Delegam ao [locationRepositoryProvider] (drift no app, REST no web).
final locationListProvider = StreamProvider<List<LocalLocation>>(
  (ref) => ref.watch(locationRepositoryProvider).watchList(),
);

/// Fonte paginada da lista (só web) — nula nos apps.
final locationListPagingProvider = Provider<PagedSource?>(
  (ref) => pagingOf(ref.watch(locationRepositoryProvider)),
);

final locationByIdProvider = StreamProvider.family<LocalLocation?, String>(
  (ref, id) => ref.watch(locationRepositoryProvider).watchById(id),
);
