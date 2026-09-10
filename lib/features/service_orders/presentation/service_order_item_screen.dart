import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../items/application/items_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../application/service_orders_provider.dart';
import 'parts_section.dart';
import 'photos_section.dart';
import 'recommendations_section.dart';

const _approvalOptions = {
  'pending': 'Pendente',
  'approved': 'Aprovado pelo cliente',
  'declined': 'Não aprovado',
};

/// Editor de um item da ordem (laudo por equipamento): diagnóstico, serviço
/// realizado, condição final, observação e a aprovação do cliente.
class ServiceOrderItemScreen extends ConsumerStatefulWidget {
  const ServiceOrderItemScreen({
    super.key,
    required this.serviceOrderId,
    required this.itemId,
  });

  final String serviceOrderId;
  final String itemId;

  @override
  ConsumerState<ServiceOrderItemScreen> createState() =>
      _ServiceOrderItemScreenState();
}

class _ServiceOrderItemScreenState
    extends ConsumerState<ServiceOrderItemScreen> {
  final _diagnosis = TextEditingController();
  final _work = TextEditingController();
  final _finalCondition = TextEditingController();
  final _note = TextEditingController();
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _diagnosis.dispose();
    _work.dispose();
    _finalCondition.dispose();
    _note.dispose();
    super.dispose();
  }

  void _seed(LocalServiceOrderItem it) {
    if (_seeded) return;
    _diagnosis.text = it.diagnosis;
    _work.text = it.workPerformed;
    _finalCondition.text = it.finalCondition;
    _note.text = it.note;
    _seeded = true;
  }

  Future<void> _save(LocalServiceOrderItem it) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(serviceOrderRepositoryProvider)
          .updateItem(
            orderId: widget.serviceOrderId,
            itemId: widget.itemId,
            baseVersion: it.version,
            diagnosis: _diagnosis.text.trim(),
            workPerformed: _work.text.trim(),
            finalCondition: _finalCondition.text.trim(),
            note: _note.text.trim(),
          );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível salvar. Fica pendente e tenta de novo.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setApproval(String value) async {
    try {
      await ref
          .read(serviceOrderRepositoryProvider)
          .setItemApproval(
            orderId: widget.serviceOrderId,
            itemId: widget.itemId,
            approval: value,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aprovação precisa de conexão. Tente de novo.'),
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover item?'),
        content: const Text('O laudo deste equipamento será removido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(serviceOrderRepositoryProvider)
        .deleteItem(orderId: widget.serviceOrderId, itemId: widget.itemId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(serviceItemsProvider(widget.serviceOrderId));
    final matches = (itemsAsync.value ?? const <LocalServiceOrderItem>[])
        .where((i) => i.id == widget.itemId);
    final item = matches.isEmpty ? null : matches.first;

    if (item == null) {
      return Scaffold(
        appBar: brandAppBar(title: 'Item'),
        body: const Center(child: Text('Item não encontrado.')),
      );
    }
    _seed(item);

    final catItem = (ref.watch(itemListProvider).value ?? const [])
        .where((i) => i.id == item.itemId)
        .firstOrNull;
    final itemName = catItem?.name ?? 'Item';
    final loc = catItem?.locationId == null
        ? null
        : (ref.watch(locationListProvider).value ?? const [])
              .where((l) => l.id == catItem!.locationId)
              .firstOrNull;

    return Scaffold(
      appBar: brandAppBar(
        title: itemName,
        subtitle: loc != null && loc.name.isNotEmpty ? loc.name : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remover item',
            onPressed: _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_diagnosis, 'Diagnóstico', lines: 3),
            const SizedBox(height: 16),
            _field(_work, 'Serviço realizado', lines: 3),
            const SizedBox(height: 16),
            _field(_finalCondition, 'Condição final', lines: 2),
            const SizedBox(height: 16),
            _field(_note, 'Observação', lines: 2),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : () => _save(item),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Aprovação do cliente',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Só os itens aprovados entram na ordem de correção.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<String>(
                segments: [
                  for (final e in _approvalOptions.entries)
                    ButtonSegment(value: e.key, label: Text(e.value)),
                ],
                selected: {item.approval},
                showSelectedIcon: false,
                onSelectionChanged: (s) => _setApproval(s.first),
              ),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Peças deste item',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            PartsSection(
              serviceOrderId: widget.serviceOrderId,
              serviceOrderItemId: widget.itemId,
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Recomendações deste item',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RecommendationsSection(
              serviceOrderId: widget.serviceOrderId,
              serviceOrderItemId: widget.itemId,
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Fotos deste item',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            PhotosSection(
              serviceOrderId: widget.serviceOrderId,
              serviceOrderItemId: widget.itemId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int lines = 1}) =>
      TextField(
        controller: c,
        maxLines: lines,
        decoration: InputDecoration(labelText: label),
      );
}
