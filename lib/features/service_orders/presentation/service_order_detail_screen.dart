import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/conflict_notice.dart';
import '../../../core/widgets/detail_view.dart';
import '../../../core/widgets/local_file_image.dart';
import '../../attachments/application/pending_uploads.dart';
import '../../attachments/application/service_order_attachments_provider.dart';
import '../../attachments/presentation/photo_capture_sheet.dart';
import '../../attachments/presentation/signature_pad_sheet.dart';
import '../../clients/application/clients_provider.dart';
import '../../equipments/application/equipments_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../../reference/data/reference_repository.dart';
import '../application/service_order_edit_controller.dart';
import '../application/service_order_part_controller.dart';
import '../../me/application/me_provider.dart';
import '../application/service_orders_provider.dart';
import '../data/recommendation_repository.dart';
import 'order_form_pickers.dart';

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
  String? _serviceOrderTypeId;
  String? _companyId;
  String? _assignedUserId;
  DateTime? _scheduledFor;
  bool _seeded = false;
  bool _seededDefaults = false; // empresa/técnico padrão (só na criação)
  final List<OrderTarget> _targets = []; // locais/equipamentos p/ virar itens
  bool _saving = false;
  bool _conflict = false;
  String? _error;

  /// Modo de edição. `_editing` liga o formulário; `_laudoOnly` restringe a
  /// edição só aos campos de laudo (diagnóstico, serviço realizado…) — o
  /// caminho para uma ordem já aberta / em andamento. O lápis do cabeçalho
  /// completo só aparece em rascunho.
  bool _editing = false;
  bool _laudoOnly = false;

  /// Atualizado a cada rebuild (não só na 1ª vez, ao contrário do
  /// `_seedFrom`) — as ações nomeadas mudam a `version` e precisam da atual.
  int? _currentVersion;

  void _reloadFromServer() {
    ref.invalidate(serviceOrderByIdProvider(widget.serviceOrderId));
    setState(() {
      _seeded = false;
      _conflict = false;
      _error = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _laudoOnly = false;
      _seeded = false;
      _conflict = false;
      _error = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _editing = widget.isNew;
    // Dados de referência REST-only: melhor esforço, pra popular os seletores.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = ref.read(referenceDataRepositoryProvider);
      for (final k in ReferenceKind.values) {
        repo.refresh(k).ignore();
      }
    });
  }

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
    _serviceOrderTypeId = order.serviceOrderTypeId;
    _companyId = order.companyId;
    _assignedUserId = order.assignedUserId;
    _scheduledFor = order.scheduledFor;
    _reasonController.text = order.reason;
    _diagnosisController.text = order.diagnosis;
    _workPerformedController.text = order.workPerformed;
    _finalConditionController.text = order.finalCondition;
    _notesController.text = order.notes;
    _seeded = true;
  }

  /// [mode] só vale na criação (`draft` | `open` | `start`); na edição é ignorado.
  Future<void> _submit({String mode = 'draft'}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.isNew && _clientId == null) {
      setState(() => _error = 'Escolha um cliente.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _conflict = false;
    });
    try {
      final controller = ref.read(serviceOrderEditControllerProvider);
      if (widget.isNew) {
        final id = await controller.create(
          clientId: _clientId!,
          serviceOrderTypeId: _serviceOrderTypeId,
          companyId: _companyId,
          assignedUserId: _assignedUserId,
          scheduledFor: _scheduledFor,
          mode: mode,
          reason: _reasonController.text.trim(),
        );
        // Cada local/equipamento escolhido vira um item da ordem.
        final repo = ref.read(serviceOrderRepositoryProvider);
        for (final t in _targets) {
          await repo.addItem(
            orderId: id,
            locationId: t.equipmentId == null ? t.locationId : null,
            equipmentId: t.equipmentId,
          );
        }
        if (!mounted) return;
        Navigator.of(context).pop();
        context.push('/service-orders/$id');
      } else {
        await controller.update(
          serviceOrderId: widget.serviceOrderId,
          baseVersion: _currentVersion,
          locationId: _locationId,
          equipmentId: _equipmentId,
          serviceOrderTypeId: _serviceOrderTypeId,
          companyId: _companyId,
          assignedUserId: _assignedUserId,
          scheduledFor: _scheduledFor,
          reason: _reasonController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
          workPerformed: _workPerformedController.text.trim(),
          finalCondition: _finalConditionController.text.trim(),
          notes: _notesController.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          _editing = false;
          _laudoOnly = false;
        });
        _reloadFromServer();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'VERSION_CONFLICT') {
        setState(() => _conflict = true);
      } else {
        setState(() => _error = e.friendlyMessage);
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

  Future<void> _runTransition(String action) async {
    setState(() {
      _saving = true;
      _error = null;
      _conflict = false;
    });
    try {
      final c = ref.read(serviceOrderEditControllerProvider);
      final v = _currentVersion;
      switch (action) {
        case 'start':
          await c.start(widget.serviceOrderId, baseVersion: v);
        case 'complete':
          await c.complete(widget.serviceOrderId, baseVersion: v);
        case 'reopen':
          await c.reopen(widget.serviceOrderId, baseVersion: v);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'VERSION_CONFLICT') {
        setState(() => _conflict = true);
      } else {
        setState(() => _error = e.friendlyMessage);
      }
    } catch (_) {
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
          _currentVersion = order.version;
          _seedFrom(order);
          return _editing
              ? _buildForm(context, order: order)
              : _viewMode(context, order);
        },
      );
    }
    // Criação: empresa emitente = a primária do usuário; técnico = ele mesmo.
    // Semeado assim que a identidade chega (o dropdown é recriado pela key).
    if (!_seededDefaults) {
      final me = ref.watch(identityProvider).value;
      if (me != null) {
        _companyId ??= me.primaryCompanyId;
        _assignedUserId ??= me.userId;
        _seededDefaults = true;
      }
    }
    return _buildForm(context, order: null);
  }

  String _refName(ReferenceKind kind, String? id) {
    if (id == null) return '';
    final items = ref.watch(referenceListProvider(kind)).value ?? const [];
    return items.where((i) => i.id == id).map((i) => i.label).join();
  }

  static String _fmtDateTime(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  Widget _viewMode(BuildContext context, LocalServiceOrder order) {
    final clientName = ref
        .watch(clientByIdProvider(order.clientId))
        .value
        ?.name;
    final locations = ref.watch(locationListProvider).value ?? const [];
    final equipments = ref.watch(equipmentListProvider).value ?? const [];
    final locationName = locations
        .where((l) => l.id == order.locationId)
        .map((l) => l.name)
        .join();
    final equipmentName = equipments
        .where((e) => e.id == order.equipmentId)
        .map((e) => e.name)
        .join();
    final isDraft = order.status == 'draft';
    final canEditLaudo = order.status != 'completed';

    final headerExtras = <Widget>[
      DetailRow(
        'Tipo',
        _refName(ReferenceKind.serviceOrderType, order.serviceOrderTypeId),
      ),
      DetailRow('Empresa', _refName(ReferenceKind.company, order.companyId)),
      DetailRow(
        'Técnico',
        _refName(ReferenceKind.orgUser, order.assignedUserId),
      ),
      DetailRow('Agendamento', _fmtDateTime(order.scheduledFor)),
    ];

    return Scaffold(
      appBar: brandAppBar(
        title: clientName ?? 'Ordem de serviço',
        count: _statusLabels[order.status] ?? order.status,
        titleSize: 20,
        actions: isDraft
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Editar',
                  onPressed: () => setState(() {
                    _editing = true;
                    _laudoOnly = false;
                  }),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(serviceOrderRepositoryProvider).refresh();
            await drainPendingUploads(ref);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: switch (order.status) {
                  'open' => OutlinedButton(
                    onPressed: _saving ? null : () => _runTransition('start'),
                    child: const Text('Iniciar'),
                  ),
                  'in_progress' => OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => _runTransition('complete'),
                    child: const Text('Concluir'),
                  ),
                  'completed' => OutlinedButton(
                    onPressed: _saving ? null : () => _runTransition('reopen'),
                    child: const Text('Reabrir'),
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
              const SizedBox(height: 8),
              DetailRow('Local', locationName),
              DetailRow('Equipamento', equipmentName),
              DetailRow('Motivo', order.reason),
              DetailExpander(
                title: 'Mais dados do cabeçalho',
                children: headerExtras,
              ),
              if (_conflict) ...[
                const SizedBox(height: 12),
                ConflictNotice(onReload: _reloadFromServer),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              _ItemsSection(
                serviceOrderId: order.id,
                clientId: order.clientId,
                canEdit: canEditLaudo,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Laudo geral',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (canEditLaudo)
                    TextButton(
                      onPressed: () => setState(() {
                        _editing = true;
                        _laudoOnly = true;
                      }),
                      child: const Text('Editar'),
                    ),
                ],
              ),
              DetailRow('Diagnóstico', order.diagnosis),
              DetailRow('Serviço realizado', order.workPerformed),
              DetailRow('Condição final', order.finalCondition),
              DetailRow('Observações', order.notes),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Peças e materiais (geral)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _PartsSection(serviceOrderId: order.id),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Recomendações para a próxima visita',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _RecommendationsSection(serviceOrderId: order.id),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              Text('Fotos', style: Theme.of(context).textTheme.titleMedium),
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
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/service-orders/${order.id}/report'),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Gerar PDF (cópia de campo)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Seletor de um dado de referência REST-only. Se o valor selecionado ainda
  /// não estiver na lista carregada (offline sem cache, ou lista chegando),
  /// mantém um item-fantasma pra não perder a seleção nem quebrar o dropdown.
  Widget _referenceDropdown({
    required ReferenceKind kind,
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    final itemsAsync = ref.watch(referenceListProvider(kind));
    final items = itemsAsync.value ?? const <ReferenceItem>[];
    final known = items.any((i) => i.id == value);
    return DropdownButtonFormField<String?>(
      // Recria o campo quando o valor muda por fora (seed de padrão) — o
      // FormField não reage a `initialValue` depois do primeiro build.
      key: ValueKey('$kind:$value'),
      initialValue: value,
      isExpanded: true,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        helperText: !enabled
            ? 'Sem permissão para trocar.'
            : (itemsAsync.hasError
                  ? 'Não foi possível carregar a lista.'
                  : null),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('—')),
        if (value != null && !known)
          DropdownMenuItem<String?>(
            value: value,
            child: const Text('(carregando…)'),
          ),
        for (final i in items)
          DropdownMenuItem<String?>(
            value: i.id,
            child: Text(
              i.subtitle.isEmpty ? i.label : '${i.label} · ${i.subtitle}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
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
        !_laudoOnly &&
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
      appBar: brandAppBar(
        title: order == null
            ? 'Nova ordem'
            : (clientNameAsync?.value?.name ?? 'Ordem de serviço'),
        count: order == null
            ? null
            : (_laudoOnly
                  ? 'Editar laudo'
                  : (_statusLabels[order.status] ?? order.status)),
        titleSize: 20,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(serviceOrderRepositoryProvider).refresh();
            await drainPendingUploads(ref);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- criação: cliente por seletor, locais/equipamentos viram itens ---
                  if (!_laudoOnly && order == null) ...[
                    ClientPickerField(
                      clientName: _clientId == null
                          ? null
                          : (clientsAsync.value ?? const <LocalClient>[])
                                .where((c) => c.id == _clientId)
                                .map((c) => c.name)
                                .join(),
                      onPick: () async {
                        final id = await pickClient(context);
                        if (id != null && mounted) {
                          setState(() {
                            _clientId = id;
                            _targets.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TargetsField(
                      clientId: _clientId,
                      targets: _targets,
                      locationName: (id) =>
                          (ref.watch(locationListProvider).value ?? const [])
                              .where((l) => l.id == id)
                              .map((l) => l.name)
                              .join(),
                      equipmentName: (id) =>
                          (ref.watch(equipmentListProvider).value ?? const [])
                              .where((e) => e.id == id)
                              .map((e) => e.name)
                              .join(),
                      onAdd: () async {
                        final picked = await pickOrderTargets(
                          context,
                          clientId: _clientId!,
                          initial: _targets.toSet(),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _targets
                              ..clear()
                              ..addAll(picked);
                          });
                        }
                      },
                      onRemove: (t) => setState(() => _targets.remove(t)),
                    ),
                    const SizedBox(height: 16),
                    _referenceDropdown(
                      kind: ReferenceKind.serviceOrderType,
                      label: 'Tipo de ordem (opcional)',
                      value: _serviceOrderTypeId,
                      onChanged: (v) => setState(() => _serviceOrderTypeId = v),
                    ),
                    const SizedBox(height: 16),
                    _referenceDropdown(
                      kind: ReferenceKind.company,
                      label: 'Empresa emitente',
                      value: _companyId,
                      enabled:
                          ref
                              .watch(permissionsProvider)
                              .value
                              ?.keys
                              .contains('service_order.assign_company') ??
                          false,
                      onChanged: (v) => setState(() => _companyId = v),
                    ),
                    const SizedBox(height: 16),
                    _referenceDropdown(
                      kind: ReferenceKind.orgUser,
                      label: 'Técnico responsável',
                      value: _assignedUserId,
                      onChanged: (v) => setState(() => _assignedUserId = v),
                    ),
                    const SizedBox(height: 16),
                    _ScheduledForField(
                      value: _scheduledFor,
                      onChanged: (v) => setState(() => _scheduledFor = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Motivo'),
                    ),
                  ],
                  // --- edição do cabeçalho (local/equipamento legados) ---
                  if (!_laudoOnly && order != null) ...[
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
                    _referenceDropdown(
                      kind: ReferenceKind.serviceOrderType,
                      label: 'Tipo de ordem (opcional)',
                      value: _serviceOrderTypeId,
                      onChanged: (v) => setState(() => _serviceOrderTypeId = v),
                    ),
                    const SizedBox(height: 16),
                    _referenceDropdown(
                      kind: ReferenceKind.company,
                      label: 'Empresa emitente (opcional)',
                      value: _companyId,
                      onChanged: (v) => setState(() => _companyId = v),
                    ),
                    const SizedBox(height: 16),
                    _referenceDropdown(
                      kind: ReferenceKind.orgUser,
                      label: 'Técnico responsável (opcional)',
                      value: _assignedUserId,
                      onChanged: (v) => setState(() => _assignedUserId = v),
                    ),
                    const SizedBox(height: 16),
                    _ScheduledForField(
                      value: _scheduledFor,
                      onChanged: (v) => setState(() => _scheduledFor = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Motivo'),
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
                  if (_conflict) ...[
                    const SizedBox(height: 12),
                    ConflictNotice(onReload: _reloadFromServer),
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
                  if (order == null) ...[
                    // Criação: o botão principal alterna Iniciar (atende agora)
                    // ↔ Agendar (tem data/hora → vai pra agenda). Rascunho fica
                    // como opção discreta abaixo.
                    FilledButton(
                      onPressed: _saving
                          ? null
                          : () => _submit(
                              mode: _scheduledFor == null ? 'start' : 'open',
                            ),
                      child: _saving
                          ? const _BtnSpinner()
                          : Text(
                              _scheduledFor == null
                                  ? 'Iniciar ordem'
                                  : 'Agendar ordem',
                            ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : () => _submit(mode: 'draft'),
                      child: const Text('Salvar rascunho'),
                    ),
                  ] else ...[
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const _BtnSpinner()
                          : const Text('Salvar'),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _cancelEdit,
                      child: const Text('Cancelar'),
                    ),
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

/// Spinner pequeno para dentro de um botão em estado de envio.
class _BtnSpinner extends StatelessWidget {
  const _BtnSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

/// Agendamento (`scheduled_for`). Data + hora; limpar zera localmente, mas o
/// backend não aceita *remover* o agendamento via REST/sync — só trocá-lo.
class _ScheduledForField extends StatelessWidget {
  const _ScheduledForField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final base = (value ?? now).toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Agendamento (opcional)',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(child: Text(value == null ? '—' : _fmt(value!))),
          TextButton(
            onPressed: () => _pick(context),
            child: Text(value == null ? 'Definir' : 'Alterar'),
          ),
          if (value != null)
            IconButton(
              tooltip: 'Limpar',
              icon: const Icon(Icons.clear),
              onPressed: () => onChanged(null),
            ),
        ],
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
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
                    child: localFileImage(item.filePath, width: 96, height: 96),
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
            child: localFileImage(
              pendingSignature.first.filePath,
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) =>
                    SignaturePadSheet(serviceOrderId: serviceOrderId),
              ),
            ),
            child: const Text('Substituir'),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => SignaturePadSheet(serviceOrderId: serviceOrderId),
        ),
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

const _priorityLabels = {'low': 'Baixa', 'medium': 'Média', 'high': 'Alta'};
const _recStatusLabels = {
  'open': 'Em aberto',
  'addressed': 'Resolvida',
  'dismissed': 'Descartada',
};

/// Lista de recomendações da ordem (REST-only, §8.4) — precisa de conexão e
/// a ordem precisa estar num status editável.
class _RecommendationsSection extends ConsumerWidget {
  const _RecommendationsSection({required this.serviceOrderId});

  final String serviceOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recommendationsProvider(serviceOrderId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => Text(
            'Não foi possível carregar as recomendações (precisa de conexão).',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (recs) {
            if (recs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nenhuma recomendação.'),
              );
            }
            return Column(
              children: [
                for (final r in recs)
                  Card(
                    child: ListTile(
                      title: Text(
                        r.description.isNotEmpty
                            ? r.description
                            : '(sem descrição)',
                      ),
                      subtitle: Text(
                        'Prioridade ${_priorityLabels[r.priority] ?? r.priority}'
                        ' · ${_recStatusLabels[r.status] ?? r.status}'
                        '${r.notes.isNotEmpty ? '\n${r.notes}' : ''}',
                      ),
                      isThreeLine: r.notes.isNotEmpty,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(recommendationRepositoryProvider)
                            .delete(serviceOrderId, r.id),
                      ),
                      onTap: () => _sheet(context, ref, rec: r),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _sheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar recomendação'),
        ),
      ],
    );
  }

  Future<void> _sheet(
    BuildContext context,
    WidgetRef ref, {
    Recommendation? rec,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _RecommendationFormSheet(serviceOrderId: serviceOrderId, rec: rec),
    );
  }
}

class _RecommendationFormSheet extends ConsumerStatefulWidget {
  const _RecommendationFormSheet({required this.serviceOrderId, this.rec});

  final String serviceOrderId;
  final Recommendation? rec;

  @override
  ConsumerState<_RecommendationFormSheet> createState() =>
      _RecommendationFormSheetState();
}

class _RecommendationFormSheetState
    extends ConsumerState<_RecommendationFormSheet> {
  late final _descController = TextEditingController(
    text: widget.rec?.description ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.rec?.notes ?? '',
  );
  late String _priority = widget.rec?.priority ?? 'medium';
  late String _status = widget.rec?.status ?? 'open';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty) {
      setState(() => _error = 'Informe a descrição.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(recommendationRepositoryProvider);
      if (widget.rec == null) {
        await repo.add(
          widget.serviceOrderId,
          description: _descController.text.trim(),
          priority: _priority,
          status: _status,
          notes: _notesController.text.trim(),
        );
      } else {
        await repo.update(
          widget.serviceOrderId,
          widget.rec!.id,
          version: widget.rec!.version,
          description: _descController.text.trim(),
          priority: _priority,
          status: _status,
          notes: _notesController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível salvar. A ordem precisa estar editável e com conexão.',
        );
      }
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
              widget.rec == null ? 'Nova recomendação' : 'Editar recomendação',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Prioridade'),
              items: [
                for (final e in _priorityLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'medium'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Situação'),
              items: [
                for (final e in _recStatusLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'open'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
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

const _approvalLabels = {
  'pending': 'Pendente',
  'approved': 'Aprovado',
  'declined': 'Não aprovado',
};

/// "Itens" numa ordem — o laudo por equipamento, agrupado por local. Opcional:
/// a ordem pode não ter item e usar só o laudo geral.
class _ItemsSection extends ConsumerWidget {
  const _ItemsSection({
    required this.serviceOrderId,
    required this.clientId,
    required this.canEdit,
  });

  final String serviceOrderId;
  final String clientId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(serviceItemsProvider(serviceOrderId));
    final locsById = {
      for (final l
          in ref.watch(locationListProvider).value ?? const <LocalLocation>[])
        l.id: l,
    };
    final equipsById = {
      for (final e
          in ref.watch(equipmentListProvider).value ?? const <LocalEquipment>[])
        e.id: e,
    };
    final items = itemsAsync.value ?? const <LocalServiceOrderItem>[];

    final byLoc = <String, List<LocalServiceOrderItem>>{};
    for (final it in items) {
      byLoc.putIfAbsent(it.locationId, () => []).add(it);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          items.isEmpty ? 'Itens' : 'Itens (${items.length})',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhum item. Adicione um equipamento para registrar o laudo dele.',
            ),
          )
        else
          for (final entry in byLoc.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                locsById[entry.key]?.name ?? 'Local',
                style: theme.textTheme.labelLarge,
              ),
            ),
            for (final it in entry.value)
              Card(
                child: ListTile(
                  title: Text(
                    it.equipmentId == null
                        ? 'Local (sem equipamento)'
                        : equipsById[it.equipmentId]?.name ?? 'Equipamento',
                  ),
                  subtitle: Text(
                    it.diagnosis.isEmpty ? 'Sem diagnóstico' : it.diagnosis,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _ApprovalChip(it.approval),
                  onTap: () => context.push(
                    '/service-orders/$serviceOrderId/items/${it.id}',
                  ),
                ),
              ),
          ],
        if (canEdit) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _addItem(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar item'),
          ),
        ],
      ],
    );
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final locations = (ref.read(locationListProvider).value ?? const [])
        .where((l) => l.clientId == clientId)
        .toList();
    if (locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um local para este cliente.')),
      );
      return;
    }
    final picked = await showModalBottomSheet<({String locId, String? eqId})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddItemSheet(clientId: clientId),
    );
    if (picked == null || !context.mounted) return;
    try {
      final id = await ref
          .read(serviceOrderRepositoryProvider)
          .addItem(
            orderId: serviceOrderId,
            locationId: picked.eqId == null ? picked.locId : null,
            equipmentId: picked.eqId,
          );
      if (context.mounted) {
        context.push('/service-orders/$serviceOrderId/items/$id');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível adicionar o item.')),
        );
      }
    }
  }
}

class _ApprovalChip extends StatelessWidget {
  const _ApprovalChip(this.approval);
  final String approval;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (approval) {
      'approved' => (const Color(0xFFE3F0E4), const Color(0xFF23502A)),
      'declined' => (const Color(0xFFF3E0DD), const Color(0xFF7C2A20)),
      _ => (const Color(0xFFEDEEF0), const Color(0xFF71757C)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: bg,
      child: Text(
        _approvalLabels[approval] ?? approval,
        style: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 10,
          color: fg,
        ),
      ),
    );
  }
}

/// Folha de seleção: escolhe o local (do cliente da ordem) e, opcionalmente,
/// um equipamento daquele local.
class _AddItemSheet extends ConsumerStatefulWidget {
  const _AddItemSheet({required this.clientId});
  final String clientId;

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  String? _locId;

  @override
  Widget build(BuildContext context) {
    final locations = (ref.watch(locationListProvider).value ?? const [])
        .where((l) => l.clientId == widget.clientId)
        .toList();
    final equipments = _locId == null
        ? const <LocalEquipment>[]
        : (ref.watch(equipmentListProvider).value ?? const [])
              .where((e) => e.locationId == _locId)
              .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Novo item', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _locId,
              decoration: const InputDecoration(labelText: 'Local'),
              items: [
                for (final l in locations)
                  DropdownMenuItem(value: l.id, child: Text(l.name)),
              ],
              onChanged: (v) => setState(() => _locId = v),
            ),
            const SizedBox(height: 12),
            if (_locId != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Equipamento (opcional)',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pop((locId: _locId!, eqId: null)),
                child: const Text('Sem equipamento — só o local'),
              ),
              for (final e in equipments)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop((locId: _locId!, eqId: e.id)),
                    child: Text(e.name),
                  ),
                ),
              if (equipments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Nenhum equipamento neste local.'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
