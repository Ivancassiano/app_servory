import 'dart:convert';

import '../../../core/db/app_database.dart';

/// Para onde levar o usuário ao tocar numa alteração pendente com erro, e o
/// que mostrar para ele saber QUAL registro é (o texto da outbox só tem ids).
class PendingTarget {
  const PendingTarget({required this.route, this.subject});

  /// Rota do app onde o registro pode ser corrigido.
  final String route;

  /// "Item Ar-condicionado · campo Cor: "Azul"" — `null` quando não há nome
  /// legível (o título "Item • editar" já diz o tipo).
  final String? subject;
}

/// Resolve o destino de uma operação da outbox olhando o banco local (a linha
/// pode ter sumido — nesse caso devolve `null` e a tela só mostra o erro).
/// Só leitura; não depende de rede, então funciona offline.
Future<PendingTarget?> resolvePendingTarget(
  AppDatabase db,
  SyncOutboxData op,
) async {
  final id = op.entityId;
  switch (op.entityType) {
    case 'client':
      final row = await (db.select(
        db.localClients,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      return PendingTarget(route: '/clients/$id', subject: row?.name);
    case 'location':
      final row = await (db.select(
        db.localLocations,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      final name = row?.name;
      return PendingTarget(
        route: '/locations/$id',
        subject: name == null || name.isEmpty ? null : name,
      );
    case 'item':
      final row = await (db.select(
        db.localItems,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      return PendingTarget(route: '/items/$id', subject: row?.name);
    case 'item_field_value':
      return _fieldValueTarget(db, op);
    case 'service_order':
      return PendingTarget(route: '/service-orders/$id');
    case 'service_order_item':
      final row = await (db.select(
        db.localServiceOrderItems,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      final orderId =
          row?.serviceOrderId ?? _payloadString(op, 'service_order_id');
      if (orderId == null) return null;
      return PendingTarget(route: '/service-orders/$orderId/items/$id');
    case 'service_order_part':
      final row = await (db.select(
        db.localServiceOrderParts,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      final orderId =
          row?.serviceOrderId ?? _payloadString(op, 'service_order_id');
      if (orderId == null) return null;
      final desc = row?.description ?? '';
      return PendingTarget(
        route: '/service-orders/$orderId',
        subject: desc.isEmpty ? null : desc,
      );
    case 'service_order_recommendation':
      final row = await (db.select(
        db.localServiceOrderRecommendations,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      final orderId =
          row?.serviceOrderId ?? _payloadString(op, 'service_order_id');
      if (orderId == null) return null;
      final desc = row?.description ?? '';
      return PendingTarget(
        route: '/service-orders/$orderId',
        subject: desc.isEmpty ? null : desc,
      );
    case 'task':
      return PendingTarget(route: '/tasks/$id');
  }
  return null; // qr_code etc.: sem tela própria para corrigir
}

/// Valor de campo personalizado: quem se edita é o ITEM (a tela do item tem o
/// formulário dos campos). O texto mostra qual campo e qual valor foi recusado
/// — é o caso "a opção da lista foi removida/renomeada".
Future<PendingTarget?> _fieldValueTarget(
  AppDatabase db,
  SyncOutboxData op,
) async {
  final row = await (db.select(
    db.localItemFieldValues,
  )..where((t) => t.id.equals(op.entityId))).getSingleOrNull();
  final itemId = row?.itemId ?? _payloadString(op, 'item_id');
  if (itemId == null) return null;
  final fieldDefId = row?.fieldDefId ?? _payloadString(op, 'field_def_id');

  final item = await (db.select(
    db.localItems,
  )..where((t) => t.id.equals(itemId))).getSingleOrNull();
  final def = fieldDefId == null
      ? null
      : await (db.select(
          db.localItemFieldDefs,
        )..where((t) => t.id.equals(fieldDefId))).getSingleOrNull();

  final parts = <String>[
    if (item != null) item.name,
    if (def != null) 'campo ${def.label}',
  ];
  var subject = parts.join(' · ');
  final raw = _payloadValue(op);
  if (subject.isNotEmpty && raw != null && raw.isNotEmpty) {
    subject = '$subject: "$raw"';
  }
  return PendingTarget(
    route: '/items/$itemId',
    subject: subject.isEmpty ? null : subject,
  );
}

Map<String, dynamic>? _payload(SyncOutboxData op) {
  try {
    final decoded = jsonDecode(op.payload);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

String? _payloadString(SyncOutboxData op, String key) {
  final v = _payload(op)?[key];
  return v is String && v.isNotEmpty ? v : null;
}

String? _payloadValue(SyncOutboxData op) {
  final v = _payload(op)?['value'];
  return v == null ? null : '$v';
}
