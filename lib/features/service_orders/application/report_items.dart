import '../../../core/db/app_database.dart';
import 'service_order_report.dart';

/// Resultado da partição: peças/fotos "gerais" (sem item) + os itens da
/// visita com suas peças e fotos.
typedef PartitionedReport = ({
  List<LocalServiceOrderPart> generalParts,
  List<ReportPhoto> generalPhotos,
  List<ReportItem> items,
});

/// Separa peças e fotos em "gerais" (`serviceOrderItemId == null`) e por item,
/// e monta a lista de [ReportItem] na ordem de `position`.
PartitionedReport partitionReport({
  required List<LocalServiceOrderPart> allParts,
  required List<LocalServiceOrderItem> itemRows,
  required Map<String, LocalItem> catalogById,
  List<ReportPhoto> allPhotos = const [],
}) {
  final general = <LocalServiceOrderPart>[];
  final byItem = <String, List<LocalServiceOrderPart>>{};
  for (final p in allParts) {
    final id = p.serviceOrderItemId;
    if (id == null) {
      general.add(p);
    } else {
      byItem.putIfAbsent(id, () => []).add(p);
    }
  }
  final generalPhotos = <ReportPhoto>[];
  final photosByItem = <String, List<ReportPhoto>>{};
  for (final ph in allPhotos) {
    final id = ph.serviceOrderItemId;
    if (id == null) {
      generalPhotos.add(ph);
    } else {
      photosByItem.putIfAbsent(id, () => []).add(ph);
    }
  }
  final rows = [...itemRows]..sort((a, b) => a.position.compareTo(b.position));
  return (
    generalParts: general,
    generalPhotos: generalPhotos,
    items: [
      for (final r in rows)
        ReportItem(
          row: r,
          itemName: catalogById[r.itemId]?.name ?? 'Item',
          parts: byItem[r.id] ?? const [],
          photos: photosByItem[r.id] ?? const [],
        ),
    ],
  );
}

String approvalLabel(String a) => switch (a) {
  'approved' => 'Aprovado pelo cliente',
  'declined' => 'Não aprovado',
  _ => 'Pendente de aprovação',
};
