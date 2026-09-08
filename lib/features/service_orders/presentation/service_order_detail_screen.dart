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
import '../../attachments/presentation/signature_pad_sheet.dart';
import '../../clients/application/clients_provider.dart';
import '../../items/application/items_provider.dart';
import '../../reference/data/reference_repository.dart';
import '../../tasks/application/task_edit_controller.dart';
import '../../tasks/application/tasks_provider.dart';
import '../application/service_order_edit_controller.dart';
import '../../me/application/me_provider.dart';
import '../application/service_orders_provider.dart';
import 'order_form_pickers.dart';
import 'parts_section.dart';
import 'photos_section.dart';
import 'recommendations_section.dart';

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
  const ServiceOrderDetailScreen({
    super.key,
    required this.serviceOrderId,
    this.presetClientId,
    this.presetItemIds = const [],
    this.fromTaskId,
  });

  final String serviceOrderId;

  /// Pré-seleção vinda de "Gerar ordem" numa tarefa (só na criação).
  final String? presetClientId;
  final List<String> presetItemIds;
  final String? fromTaskId;

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
  String? _itemId;
  String? _serviceOrderTypeId;
  String? _companyId;
  String? _assignedUserId;
  DateTime? _scheduledFor;
  bool _seeded = false;
  bool _seededDefaults = false; // empresa/técnico padrão (só na criação)
  final List<OrderTarget> _targets = []; // itens do cadastro p/ virar linhas
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
    if (widget.isNew) {
      _clientId = widget.presetClientId;
      _targets.addAll(widget.presetItemIds.map((id) => (itemId: id)));
    }
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
    _itemId = order.itemId;
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
          await repo.addItem(orderId: id, itemId: t.itemId);
        }
        // Veio de "Gerar ordem" numa tarefa → conclui a tarefa e a vincula.
        if (widget.fromTaskId != null) {
          try {
            final task = await ref
                .read(taskRepositoryProvider)
                .watchById(widget.fromTaskId!)
                .first;
            await ref
                .read(taskEditControllerProvider)
                .transition(
                  taskId: widget.fromTaskId!,
                  baseVersion: task?.version,
                  action: 'complete',
                  generatedOrderId: id,
                );
          } catch (_) {
            // não impede a ordem de ser criada
          }
        }
        if (!mounted) return;
        Navigator.of(context).pop();
        context.push('/service-orders/$id');
      } else {
        await controller.update(
          serviceOrderId: widget.serviceOrderId,
          baseVersion: _currentVersion,
          itemId: _itemId,
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
    final itemName = (ref.watch(itemListProvider).value ?? const [])
        .where((i) => i.id == order.itemId)
        .map((i) => i.name)
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
              if (order.parentOrderId != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.undo, size: 16),
                    label: const Text('Retorno de uma visita'),
                    onPressed: () =>
                        context.push('/service-orders/${order.parentOrderId}'),
                  ),
                ),
              if (itemName.isNotEmpty) DetailRow('Item', itemName),
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
              _FollowUpSection(order: order, saving: _saving),
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
              PartsSection(serviceOrderId: order.id),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Recomendações para a próxima visita',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              RecommendationsSection(serviceOrderId: order.id),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Fotos (geral)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              PhotosSection(serviceOrderId: order.id),
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
    final itemsAsync = ref.watch(itemListProvider);
    final clientNameAsync = order == null
        ? null
        : ref.watch(clientByIdProvider(order.clientId));

    // Enquanto local/equipamento ainda não carregaram (1ª renderização após
    // abrir o app), a lista filtrada abaixo estaria vazia e o valor
    // selecionado (vindo do `_seedFrom`) não bateria com nenhum item —
    // achado ao editar uma ordem logo após reabrir o app: sem esta guarda,
    // o dropdown "perdia" a seleção permanentemente (o valor herdado do
    // servidor continuava intacto, só a tela local mostrava errado).
    if (order != null && !_laudoOnly && !itemsAsync.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final clientItems =
        (itemsAsync.value ?? const <LocalItem>[])
            .where((i) => i.clientId == _clientId)
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final displayItemId = clientItems.any((i) => i.id == _itemId)
        ? _itemId
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
                      itemName: (id) =>
                          (ref.watch(itemListProvider).value ?? const [])
                              .where((i) => i.id == id)
                              .map((i) => i.name)
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
                  // --- edição do cabeçalho ---
                  if (!_laudoOnly && order != null) ...[
                    DropdownButtonFormField<String?>(
                      initialValue: displayItemId,
                      decoration: const InputDecoration(
                        labelText: 'Item (opcional)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('—'),
                        ),
                        ...clientItems.map(
                          (i) => DropdownMenuItem<String?>(
                            value: i.id,
                            child: Text(i.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _itemId = v),
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
    final catById = {
      for (final i in ref.watch(itemListProvider).value ?? const <LocalItem>[])
        i.id: i,
    };
    final items = itemsAsync.value ?? const <LocalServiceOrderItem>[];

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
            child: Text('Nenhum item. Adicione um item para o laudo dele.'),
          )
        else
          for (final it in items)
            Card(
              child: ListTile(
                title: Text(catById[it.itemId]?.name ?? 'Item'),
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
        if (canEdit) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _addItems(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar item'),
          ),
        ],
      ],
    );
  }

  Future<void> _addItems(BuildContext context, WidgetRef ref) async {
    final picked = await pickOrderTargets(
      context,
      clientId: clientId,
      initial: const {},
    );
    if (picked == null || picked.isEmpty || !context.mounted) return;
    try {
      final repo = ref.read(serviceOrderRepositoryProvider);
      String? lastId;
      for (final t in picked) {
        lastId = await repo.addItem(orderId: serviceOrderId, itemId: t.itemId);
      }
      if (context.mounted && picked.length == 1 && lastId != null) {
        context.push('/service-orders/$serviceOrderId/items/$lastId');
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
        style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 10, color: fg),
      ),
    );
  }
}

/// Bloco "Aplicação das correções" (spec §7.6): mostra as ordens-filhas já
/// agendadas e, quando há item aprovado, o botão para agendar uma nova.
class _FollowUpSection extends ConsumerWidget {
  const _FollowUpSection({required this.order, required this.saving});

  final LocalServiceOrder order;
  final bool saving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(serviceItemsProvider(order.id)).value ?? const [];
    final approved = items.where((i) => i.approval == 'approved').length;
    final children = ref.watch(childServiceOrdersProvider(order.id));
    if (approved == 0 && children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'Aplicação das correções',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final c in children)
          Card(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.event_available),
              title: Text(
                c.scheduledFor == null
                    ? 'Correção (${_statusLabels[c.status] ?? c.status})'
                    : 'Agendada: ${_fmtShortDate(c.scheduledFor!)}',
              ),
              subtitle: Text(_statusLabels[c.status] ?? c.status),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/service-orders/${c.id}'),
            ),
          ),
        if (approved > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text('Agendar correções ($approved aprovados)'),
              onPressed: saving ? null : () => _schedule(context, ref),
            ),
          ),
      ],
    );
  }

  Future<void> _schedule(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      helpText: 'Data da aplicação das correções',
    );
    if (picked == null || !context.mounted) return;
    try {
      final id = await ref
          .read(serviceOrderRepositoryProvider)
          .createFollowUp(parentOrderId: order.id, scheduledFor: picked);
      if (context.mounted) context.push('/service-orders/$id');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível agendar as correções.'),
          ),
        );
      }
    }
  }
}

String _fmtShortDate(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year}';
}
