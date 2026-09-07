import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../application/service_order_part_controller.dart';
import '../application/service_orders_provider.dart';

/// Lista de peças/materiais da ordem. `serviceOrderItemId` nulo = as peças
/// **gerais** (sem item); setado = só as daquele item da visita (e novas ficam
/// vinculadas a ele).
class PartsSection extends ConsumerWidget {
  const PartsSection({
    super.key,
    required this.serviceOrderId,
    this.serviceOrderItemId,
  });

  final String serviceOrderId;
  final String? serviceOrderItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(servicePartsProvider(serviceOrderId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        partsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erro ao carregar peças: $e'),
          data: (all) {
            final parts = [
              for (final p in all)
                if (p.serviceOrderItemId == serviceOrderItemId) p,
            ];
            if (parts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nenhuma peça adicionada.'),
              );
            }
            return Column(
              children: parts
                  .map(
                    (part) => Card(
                      child: ListTile(
                        title: Text(
                          part.description.isNotEmpty
                              ? part.description
                              : '(sem descrição)',
                        ),
                        subtitle: Text(
                          '${part.quantity} ${part.unit}'
                          '${part.unitPrice != null ? ' · R\$ ${part.unitPrice}' : ''}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref
                              .read(serviceOrderPartControllerProvider)
                              .deletePart(
                                serviceOrderId: serviceOrderId,
                                partId: part.id,
                                baseVersion: part.version,
                              ),
                        ),
                        onTap: () => _showPartSheet(context, ref, part: part),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showPartSheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar peça'),
        ),
      ],
    );
  }

  Future<void> _showPartSheet(
    BuildContext context,
    WidgetRef ref, {
    LocalServiceOrderPart? part,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PartFormSheet(
        serviceOrderId: serviceOrderId,
        serviceOrderItemId: serviceOrderItemId,
        part: part,
      ),
    );
  }
}

class _PartFormSheet extends ConsumerStatefulWidget {
  const _PartFormSheet({
    required this.serviceOrderId,
    required this.serviceOrderItemId,
    this.part,
  });

  final String serviceOrderId;
  final String? serviceOrderItemId;
  final LocalServiceOrderPart? part;

  @override
  ConsumerState<_PartFormSheet> createState() => _PartFormSheetState();
}

class _PartFormSheetState extends ConsumerState<_PartFormSheet> {
  late final _descriptionController = TextEditingController(
    text: widget.part?.description ?? '',
  );
  late final _partNumberController = TextEditingController(
    text: widget.part?.partNumber ?? '',
  );
  late final _quantityController = TextEditingController(
    text: widget.part?.quantity ?? '1',
  );
  late final _unitController = TextEditingController(
    text: widget.part?.unit ?? '',
  );
  late final _unitCostController = TextEditingController(
    text: widget.part?.unitCost ?? '',
  );
  late final _unitPriceController = TextEditingController(
    text: widget.part?.unitPrice ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.part?.notes ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _partNumberController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _unitCostController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final controller = ref.read(serviceOrderPartControllerProvider);
    try {
      if (widget.part == null) {
        await controller.addPart(
          serviceOrderId: widget.serviceOrderId,
          description: _descriptionController.text.trim(),
          partNumber: _partNumberController.text.trim(),
          quantity: _quantityController.text.trim(),
          unit: _unitController.text.trim(),
          unitCost: _unitCostController.text.trim(),
          unitPrice: _unitPriceController.text.trim(),
          notes: _notesController.text.trim(),
          serviceOrderItemId: widget.serviceOrderItemId,
        );
      } else {
        await controller.updatePart(
          serviceOrderId: widget.serviceOrderId,
          partId: widget.part!.id,
          baseVersion: widget.part!.version,
          description: _descriptionController.text.trim(),
          partNumber: _partNumberController.text.trim(),
          quantity: _quantityController.text.trim(),
          unit: _unitController.text.trim(),
          unitCost: _unitCostController.text.trim(),
          unitPrice: _unitPriceController.text.trim(),
          notes: _notesController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom:
            16 +
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.part == null ? 'Adicionar peça' : 'Editar peça',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partNumberController,
              decoration: const InputDecoration(labelText: 'Código/referência'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: 'Unidade'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitCostController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Custo unitário',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Preço unitário',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
