import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../clients/application/clients_provider.dart';
import '../data/service_order_repository.dart';

export '../data/service_order_repository.dart'
    show serviceOrderRepositoryProvider;

/// Uma ordem + o nome do cliente. O join (antes em SQL) virou combinação de
/// dois providers — funciona igual no app (drift) e no web (REST).
class ServiceOrderWithClient {
  const ServiceOrderWithClient({required this.order, required this.clientName});

  final LocalServiceOrder order;
  final String clientName;
}

final _serviceOrdersRawProvider = StreamProvider<List<LocalServiceOrder>>(
  (ref) => ref.watch(serviceOrderRepositoryProvider).watchList(),
);

final serviceOrderListProvider =
    Provider<AsyncValue<List<ServiceOrderWithClient>>>((ref) {
  final ordersAsync = ref.watch(_serviceOrdersRawProvider);
  final clients = ref.watch(clientListProvider).value ?? const [];
  final nameById = {for (final c in clients) c.id: c.name};
  return ordersAsync.whenData(
    (orders) => [
      for (final o in orders)
        ServiceOrderWithClient(
          order: o,
          clientName: nameById[o.clientId] ?? '—',
        ),
    ],
  );
});

final serviceOrderByIdProvider =
    StreamProvider.family<LocalServiceOrder?, String>(
  (ref, id) => ref.watch(serviceOrderRepositoryProvider).watchById(id),
);

final servicePartsProvider =
    StreamProvider.family<List<LocalServiceOrderPart>, String>(
  (ref, orderId) =>
      ref.watch(serviceOrderRepositoryProvider).watchParts(orderId),
);
