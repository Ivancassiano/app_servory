import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/label_batch_repository.dart';

const _batchStatus = {
  'created': 'Criado',
  'reserved': 'Reservado',
  'issued': 'Emitido',
  'lost': 'Perdido',
};

class LabelBatchListScreen extends ConsumerWidget {
  const LabelBatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(labelBatchListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Etiquetas')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(labelBatchRepositoryProvider).refresh(),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('Não foi possível carregar.\n$e')),
              ),
            ],
          ),
          data: (batches) {
            if (batches.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhum lote de etiquetas. Toque em + para gerar.',
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: batches.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final b = batches[i];
                return ListTile(
                  title: Text(b.label.isNotEmpty ? b.label : 'Lote sem nome'),
                  subtitle: Text(
                    '${b.quantity} etiquetas · ${_batchStatus[b.status] ?? b.status}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/label-batches/${b.id}'),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createDialog(context, ref),
        tooltip: 'Novo lote',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createDialog(BuildContext context, WidgetRef ref) async {
    final labelCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '20');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo lote de etiquetas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Nome do lote'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Quantidade (1 a 500)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gerar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
    if (qty < 1 || qty > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantidade entre 1 e 500.')),
      );
      return;
    }
    try {
      final batch = await ref.read(labelBatchRepositoryProvider).create(
            label: labelCtrl.text.trim(),
            quantity: qty,
          );
      if (context.mounted) context.push('/label-batches/${batch.id}');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível gerar o lote.')),
        );
      }
    }
  }
}
