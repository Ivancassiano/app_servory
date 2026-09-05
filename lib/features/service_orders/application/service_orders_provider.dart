import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../sync/application/sync_provider.dart';

/// Uma ordem + o nome do cliente, resolvido via join — evita uma consulta
/// por linha na lista (a tabela local não guarda nome de cliente
/// desnormalizado).
class ServiceOrderWithClient {
  const ServiceOrderWithClient({required this.order, required this.clientName});

  final LocalServiceOrder order;
  final String clientName;
}

final serviceOrderListProvider = StreamProvider<List<ServiceOrderWithClient>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  final query =
      db.select(db.localServiceOrders).join([
          leftOuterJoin(
            db.localClients,
            db.localClients.id.equalsExp(db.localServiceOrders.clientId),
          ),
        ])
        ..where(db.localServiceOrders.deleted.equals(false))
        ..orderBy([
          OrderingTerm(
            expression: db.localServiceOrders.localUpdatedAt,
            mode: OrderingMode.desc,
          ),
        ]);
  return query.watch().map(
    (rows) => rows
        .map(
          (row) => ServiceOrderWithClient(
            order: row.readTable(db.localServiceOrders),
            clientName: row.readTableOrNull(db.localClients)?.name ?? '—',
          ),
        )
        .toList(),
  );
});

final serviceOrderByIdProvider =
    StreamProvider.family<LocalServiceOrder?, String>((ref, id) {
      final db = ref.watch(appDatabaseProvider);
      final query = db.select(db.localServiceOrders)
        ..where((t) => t.id.equals(id));
      return query.watchSingleOrNull();
    });

final servicePartsProvider =
    StreamProvider.family<List<LocalServiceOrderPart>, String>((
      ref,
      serviceOrderId,
    ) {
      final db = ref.watch(appDatabaseProvider);
      final query = db.select(db.localServiceOrderParts)
        ..where(
          (t) =>
              t.serviceOrderId.equals(serviceOrderId) & t.deleted.equals(false),
        )
        ..orderBy([(t) => OrderingTerm(expression: t.localUpdatedAt)]);
      return query.watch();
    });
