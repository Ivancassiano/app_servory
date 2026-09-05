import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../sync/application/sync_provider.dart';
import 'attachments_api_provider.dart';
import 'service_order_attachments_provider.dart';

/// Pendências de upload de uma ordem — a tela usa pra mostrar o que ainda
/// não chegou ao servidor (GUIA-FLUTTER.md §7.4: a ordem não deve ser
/// tratada como "totalmente sincronizada" enquanto isto não estiver vazio).
final uploadQueueForOrderProvider =
    StreamProvider.family<List<UploadQueueData>, String>((ref, serviceOrderId) {
      final db = ref.watch(appDatabaseProvider);
      final query = db.select(db.uploadQueue)
        ..where((t) => t.serviceOrderId.equals(serviceOrderId))
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
      return query.watch();
    });

/// Drena a fila de upload (GUIA-FLUTTER.md §7.3): tenta enviar cada item
/// pendente; sucesso remove a linha (mantém o arquivo — a fatia de PDF
/// local vai precisar dele); falha incrementa `attempts`/grava
/// `lastError` e mantém na fila pra tentar de novo depois.
class UploadQueueRunner extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  bool _draining = false;

  /// Chamado de vários lugares (logo após enfileirar, puxar-pra-atualizar) —
  /// sem esta trava, duas chamadas concorrentes leriam a mesma leva de
  /// pendências e enviariam o mesmo arquivo duas vezes (o servidor não tem
  /// idempotência por `sha256` pra fotos/assinatura, diferente do outbox de
  /// sync). Uma chamada que chega enquanto outra já está em andamento só
  /// não faz nada — a fila já vai ser drenada pela que está rodando.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      await _drainOnce();
    } finally {
      _draining = false;
    }
  }

  Future<void> _drainOnce() async {
    final db = ref.read(appDatabaseProvider);
    final api = ref.read(attachmentsApiProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final pending = await db.select(db.uploadQueue).get();
      for (final item in pending) {
        try {
          final file = File(item.filePath);
          if (item.kind == 'photo') {
            await api.addPhoto(
              serviceOrderId: item.serviceOrderId,
              file: file,
              kind: item.photoKind,
              caption: item.caption,
            );
          } else {
            await api.putSignature(
              serviceOrderId: item.serviceOrderId,
              file: file,
            );
          }
          await (db.delete(
            db.uploadQueue,
          )..where((t) => t.id.equals(item.id))).go();
          // Sem isto, a seção de fotos/assinatura fica presa no estado de
          // antes do envio até a tela recarregar por outro motivo — achado
          // ao testar o envio da assinatura ao vivo.
          if (item.kind == 'photo') {
            ref.invalidate(orderPhotosProvider(item.serviceOrderId));
          } else {
            ref.invalidate(orderSignatureProvider(item.serviceOrderId));
          }
        } catch (e) {
          await (db.update(
            db.uploadQueue,
          )..where((t) => t.id.equals(item.id))).write(
            UploadQueueCompanion(
              attempts: Value(item.attempts + 1),
              lastError: Value(e.toString()),
            ),
          );
        }
      }
    });
  }
}

final uploadQueueRunnerProvider =
    NotifierProvider<UploadQueueRunner, AsyncValue<void>>(
      UploadQueueRunner.new,
    );
