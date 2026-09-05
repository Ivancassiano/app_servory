import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../attachments/application/service_order_attachments_provider.dart';
import '../../attachments/application/upload_queue_provider.dart';
import '../../attachments/presentation/photo_capture_sheet.dart';
import '../../attachments/presentation/signature_pad_sheet.dart';
import '../../clients/application/clients_provider.dart';
import '../../equipments/application/equipments_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../../sync/application/sync_provider.dart';
import '../application/service_order_edit_controller.dart';
import '../application/service_order_part_controller.dart';
import '../application/service_orders_provider.dart';

const _statusLabels = {
  'draft': 'Rascunho',
  'open': 'Aberta',
  'in_progress': 'Em andamento',
  'completed': 'Concluída',
};

/// `serviceOrderId == 'new'` é o sentinela de criação (mesmo padrão de
/// `ClientDetailScreen`). `client_id` só é escolhido na criação — imutável
/// depois (o protocolo de sync não aceita mudar, GUIA-FLUTTER.md §8.4).
class ServiceOrderDetailScreen extends ConsumerStatefulWidget {
  const ServiceOrderDetailScreen({super.key, required this.serviceOrderId});

  final String serviceOrderId;
  bool get isNew => serviceOrderId == 'new';

  @override
  ConsumerState<ServiceOrderDetailScreen> createState() =>
      _ServiceOrderDetailScreenState();
}

class _ServiceOrderDetailScreenState
    extends ConsumerState<ServiceOrderDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _workPerformedController = TextEditingController();
  final _finalConditionController = TextEditingController();
  final _notesController = TextEditingController();

  String? _clientId;
  String? _locationId;
  String? _equipmentId;
  bool _openNow = false;
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    _diagnosisController.dispose();
    _workPerformedController.dispose();
    _finalConditionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _seedFrom(LocalServiceOrder order) {
    if (_seeded) return;
    _clientId = order.clientId;
    _locationId = order.locationId;
    _equipmentId = order.equipmentId;
    _reasonController.text = order.reason;
    _diagnosisController.text = order.diagnosis;
    _workPerformedController.text = order.workPerformed;
    _finalConditionController.text = order.finalCondition;
    _notesController.text = order.notes;
    _seeded = true;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.isNew && _clientId == null) {
      setState(() => _error = 'Escolha um cliente.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(serviceOrderEditControllerProvider);
      if (widget.isNew) {
        final id = await controller.create(
          clientId: _clientId!,
          locationId: _locationId,
          equipmentId: _equipmentId,
          open: _openNow,
          reason: _reasonController.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        context.push('/service-orders/$id');
      } else {
        await controller.update(
          serviceOrderId: widget.serviceOrderId,
          locationId: _locationId,
          equipmentId: _equipmentId,
          reason: _reasonController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
          workPerformed: _workPerformedController.text.trim(),
          finalCondition: _finalConditionController.text.trim(),
          notes: _notesController.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error =
            'Não foi possível salvar. Os dados ficam pendentes e tentam de novo sozinhos.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runTransition(Future<void> Function(String) action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action(widget.serviceOrderId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível registrar a transição.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isNew) {
      final orderAsync = ref.watch(
        serviceOrderByIdProvider(widget.serviceOrderId),
      );
      return orderAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Erro: $e')),
        ),
        data: (order) {
          if (order == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Ordem não encontrada.')),
            );
          }
          _seedFrom(order);
          return _buildForm(context, order: order);
        },
      );
    }
    return _buildForm(context, order: null);
  }

  Widget _buildForm(BuildContext context, {required LocalServiceOrder? order}) {
    final clientsAsync = ref.watch(clientListProvider);
    final locationsAsync = ref.watch(locationListProvider);
    final equipmentsAsync = ref.watch(equipmentListProvider);
    final clientNameAsync = order == null
        ? null
        : ref.watch(clientByIdProvider(order.clientId));

    // Enquanto local/equipamento ainda não carregaram (1ª renderização após
    // abrir o app), a lista filtrada abaixo estaria vazia e o valor
    // selecionado (vindo do `_seedFrom`) não bateria com nenhum item —
    // achado ao editar uma ordem logo após reabrir o app: sem esta guarda,
    // o dropdown "perdia" a seleção permanentemente (o valor herdado do
    // servidor continuava intacto, só a tela local mostrava errado).
    if (order != null &&
        (!locationsAsync.hasValue || !equipmentsAsync.hasValue)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final locations = (locationsAsync.value ?? const <LocalLocation>[])
        .where((l) => l.clientId == _clientId)
        .toList();
    final equipments = (equipmentsAsync.value ?? const <LocalEquipment>[])
        .where((e) => e.locationId == _locationId)
        .toList();
    // Valor exibido no dropdown: nunca sobrescreve `_locationId`/
    // `_equipmentId` diretamente (isso corrigia o sintoma escondendo a
    // causa) — só usa `null` na tela quando o id selecionado realmente não
    // está entre as opções carregadas.
    final displayLocationId = locations.any((l) => l.id == _locationId)
        ? _locationId
        : null;
    final displayEquipmentId = equipments.any((e) => e.id == _equipmentId)
        ? _equipmentId
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          order == null
              ? 'Nova ordem'
              : (clientNameAsync?.value?.name ?? 'Ordem de serviço'),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(syncRunnerProvider.notifier).runSync();
            await ref.read(uploadQueueRunnerProvider.notifier).drain();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (order != null) ...[
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            _statusLabels[order.status] ?? order.status,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (order.status == 'open')
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _runTransition(
                                    (id) => ref
                                        .read(
                                          serviceOrderEditControllerProvider,
                                        )
                                        .start(id),
                                  ),
                            child: const Text('Iniciar'),
                          ),
                        if (order.status == 'in_progress')
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _runTransition(
                                    (id) => ref
                                        .read(
                                          serviceOrderEditControllerProvider,
                                        )
                                        .complete(id),
                                  ),
                            child: const Text('Concluir'),
                          ),
                        if (order.status == 'completed')
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _runTransition(
                                    (id) => ref
                                        .read(
                                          serviceOrderEditControllerProvider,
                                        )
                                        .reopen(id),
                                  ),
                            child: const Text('Reabrir'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (order == null) ...[
                    clientsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Erro ao carregar clientes: $e'),
                      data: (clients) => DropdownButtonFormField<String>(
                        initialValue: _clientId,
                        decoration: const InputDecoration(labelText: 'Cliente'),
                        items: clients
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _clientId = v;
                          _locationId = null;
                          _equipmentId = null;
                        }),
                        validator: (v) =>
                            v == null ? 'Escolha um cliente.' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String?>(
                    initialValue: displayLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Local (opcional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('—'),
                      ),
                      ...locations.map(
                        (l) => DropdownMenuItem<String?>(
                          value: l.id,
                          child: Text(l.name),
                        ),
                      ),
                    ],
                    onChanged: _clientId == null
                        ? null
                        : (v) => setState(() {
                            _locationId = v;
                            _equipmentId = null;
                          }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: displayEquipmentId,
                    decoration: const InputDecoration(
                      labelText: 'Equipamento (opcional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('—'),
                      ),
                      ...equipments.map(
                        (e) => DropdownMenuItem<String?>(
                          value: e.id,
                          child: Text(e.name),
                        ),
                      ),
                    ],
                    onChanged: _locationId == null
                        ? null
                        : (v) => setState(() => _equipmentId = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(labelText: 'Motivo'),
                  ),
                  if (order == null) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Abrir imediatamente'),
                      subtitle: const Text(
                        'Desligado salva como rascunho (não visível na agenda).',
                      ),
                      value: _openNow,
                      onChanged: (v) => setState(() => _openNow = v),
                    ),
                  ],
                  if (order != null) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _diagnosisController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Diagnóstico',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _workPerformedController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Serviço realizado',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _finalConditionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Condição final',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
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
                  if (order != null) ...[
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Peças e materiais',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _PartsSection(serviceOrderId: order.id),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Fotos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _PhotosSection(serviceOrderId: order.id),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Assinatura',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _SignatureSection(serviceOrderId: order.id),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotosSection extends ConsumerWidget {
  const _PhotosSection({required this.serviceOrderId});

  final String serviceOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadedAsync = ref.watch(orderPhotosProvider(serviceOrderId));
    final pendingAsync = ref.watch(uploadQueueForOrderProvider(serviceOrderId));
    final pendingPhotos = (pendingAsync.value ?? const <UploadQueueData>[])
        .where((i) => i.kind == 'photo')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...uploadedAsync.maybeWhen(
              data: (photos) => photos
                  .map(
                    (photo) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photo.downloadUrl,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 96,
                          height: 96,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              orElse: () => const [],
            ),
            ...pendingPhotos.map(
              (item) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(item.filePath),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Positioned(
                    right: 2,
                    top: 2,
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => PhotoCaptureSheet(serviceOrderId: serviceOrderId),
          ),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Adicionar foto'),
        ),
      ],
    );
  }
}

class _SignatureSection extends ConsumerWidget {
  const _SignatureSection({required this.serviceOrderId});

  final String serviceOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signatureAsync = ref.watch(orderSignatureProvider(serviceOrderId));
    final pendingAsync = ref.watch(uploadQueueForOrderProvider(serviceOrderId));
    final pendingSignature = (pendingAsync.value ?? const <UploadQueueData>[])
        .where((i) => i.kind == 'signature')
        .toList();

    // Pendente vem ANTES de já-enviada: se o usuário tocou "Substituir" e
    // ainda não sincronizou, mostrar a assinatura antiga como se fosse a
    // atual escondia que já existe uma substituição enfileirada (achado na
    // revisão) — o usuário só via "Substituir" de novo, sem indicação de
    // que já tinha uma pendente.
    final existing = signatureAsync.value;
    if (pendingSignature.isNotEmpty) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(pendingSignature.first.filePath),
              width: 120,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pendingSignature.first.lastError != null
                  ? 'Pendente de envio (erro: ${pendingSignature.first.lastError})'
                  : 'Pendente de envio',
            ),
          ),
        ],
      );
    }

    if (existing != null) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              existing.downloadUrl,
              width: 120,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                width: 120,
                height: 80,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => SignaturePadSheet(serviceOrderId: serviceOrderId),
            ),
            child: const Text('Substituir'),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SignaturePadSheet(serviceOrderId: serviceOrderId),
      ),
      icon: const Icon(Icons.draw_outlined),
      label: const Text('Coletar assinatura'),
    );
  }
}

class _PartsSection extends ConsumerWidget {
  const _PartsSection({required this.serviceOrderId});

  final String serviceOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(servicePartsProvider(serviceOrderId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        partsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erro ao carregar peças: $e'),
          data: (parts) {
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
                              .deletePart(part.id),
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
      builder: (_) =>
          _PartFormSheet(serviceOrderId: serviceOrderId, part: part),
    );
  }
}

class _PartFormSheet extends ConsumerStatefulWidget {
  const _PartFormSheet({required this.serviceOrderId, this.part});

  final String serviceOrderId;
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
        );
      } else {
        await controller.updatePart(
          partId: widget.part!.id,
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
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
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
