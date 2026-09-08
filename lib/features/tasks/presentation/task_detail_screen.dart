import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/detail_view.dart';
import '../../clients/application/clients_provider.dart';
import '../../clients/presentation/client_picker.dart';
import '../../items/application/items_provider.dart';
import '../../me/application/me_provider.dart';
import '../../reference/data/reference_repository.dart';
import '../application/task_edit_controller.dart';
import '../application/tasks_provider.dart';
import 'task_list_screen.dart' show taskStatusLabels;
import 'task_targets_field.dart';

/// Detalhe + criação + edição de uma tarefa. `taskId == 'new'` = criação.
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    this.presetClientId,
  });

  final String taskId;
  final String? presetClientId;
  bool get isNew => taskId == 'new';

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _notes = TextEditingController();

  String? _clientId;
  String? _taskTypeId;
  String? _assignedUserId;
  String? _companyId;
  DateTime? _scheduledFor;
  bool _allDay = false;
  bool _showSchedule = false;
  List<TaskTargetInput> _targets = [];

  int? _version;
  bool _seeded = false;
  bool _targetsSeeded = false;
  bool _seededDefaults = false;
  bool _viewMode = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clientId = widget.presetClientId;
    _viewMode = !widget.isNew;
  }

  @override
  void dispose() {
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _seedFrom(LocalTask t) {
    if (_seeded) return;
    _seeded = true;
    _clientId = t.clientId;
    _version = t.version;
    _taskTypeId = t.taskTypeId;
    _assignedUserId = t.assignedUserId;
    _companyId = t.companyId;
    _scheduledFor = t.scheduledFor;
    _allDay = t.scheduledAllDay;
    _showSchedule = t.scheduledFor != null;
    _description.text = t.description;
    _notes.text = t.notes;
  }

  TaskFields _collect() => TaskFields(
    description: _description.text.trim(),
    notes: _notes.text.trim(),
    taskTypeId: _taskTypeId,
    assignedUserId: _assignedUserId,
    companyId: _companyId,
    scheduledFor: _showSchedule ? _scheduledFor : null,
    scheduledAllDay: _allDay,
    targets: _targets,
  );

  Future<void> _submit(LocalTask? existing) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_clientId == null) {
      setState(() => _error = 'Selecione o cliente.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ctrl = ref.read(taskEditControllerProvider);
      if (existing == null) {
        final id = await ctrl.create(clientId: _clientId!, fields: _collect());
        if (mounted) context.pushReplacement('/tasks/$id');
      } else {
        await ctrl.update(
          taskId: existing.id,
          baseVersion: _version,
          fields: _collect(),
        );
        if (mounted) setState(() => _viewMode = true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível salvar. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _transition(LocalTask t, String action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(taskEditControllerProvider)
          .transition(taskId: t.id, baseVersion: t.version, action: action);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível registrar.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(LocalTask t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir tarefa'),
        content: const Text('A tarefa será removida. Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(taskEditControllerProvider)
          .delete(taskId: t.id, baseVersion: t.version);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível excluir.');
    }
  }

  /// "Gerar ordem": itens explícitos + itens dos locais-alvo, deduplicados.
  void _generateOrder(LocalTask t) {
    final ids = <String>{};
    for (final tg in _targets) {
      if (tg.itemId != null) ids.add(tg.itemId!);
      if (tg.locationId != null && tg.itemId == null) {
        for (final it in ref.read(itemsByLocationProvider(tg.locationId!))) {
          ids.add(it.id);
        }
      }
    }
    final q = <String>[
      'presetClientId=${t.clientId}',
      if (ids.isNotEmpty) 'presetItemIds=${ids.join(',')}',
      'fromTaskId=${t.id}',
    ].join('&');
    context.push('/service-orders/new?$q');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isNew) return _form(context, null);
    final async = ref.watch(taskByIdProvider(widget.taskId));
    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: brandAppBar(title: 'Tarefa'),
        body: Center(child: Text('$e')),
      ),
      data: (t) {
        if (t == null) {
          return Scaffold(
            appBar: brandAppBar(title: 'Tarefa'),
            body: const Center(child: Text('Tarefa não encontrada.')),
          );
        }
        _seedFrom(t);
        _seedTargets();
        return _viewMode ? _view(context, t) : _form(context, t);
      },
    );
  }

  void _seedTargets() {
    if (_targetsSeeded) return;
    final rows = ref.watch(taskTargetsProvider(widget.taskId)).value;
    if (rows == null) return;
    _targetsSeeded = true;
    _targets = [
      for (final r in rows)
        TaskTargetInput(locationId: r.locationId, itemId: r.itemId),
    ];
  }

  String _refName(ReferenceKind kind, String? id) {
    if (id == null) return '';
    final items = ref.watch(referenceListProvider(kind)).value ?? const [];
    return items.where((i) => i.id == id).map((i) => i.label).join();
  }

  static String _fmt(DateTime? d, bool allDay) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(l.day)}/${two(l.month)}/${l.year}';
    return allDay ? date : '$date ${two(l.hour)}:${two(l.minute)}';
  }

  Widget _view(BuildContext context, LocalTask t) {
    final clientName = ref.watch(clientByIdProvider(t.clientId)).value?.name;
    final targetRows = ref.watch(taskTargetsProvider(t.id)).value ?? const [];
    final targets = [
      for (final r in targetRows)
        TaskTargetInput(locationId: r.locationId, itemId: r.itemId),
    ];

    return Scaffold(
      appBar: brandAppBar(
        title: t.description.isEmpty ? 'Tarefa' : t.description,
        subtitle: clientName,
        count: taskStatusLabels[t.status] ?? t.status,
        actions: [
          if (t.status == 'open')
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() {
                _viewMode = false;
                _seeded = false;
                _targetsSeeded = false;
              }),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailRow('Cliente', clientName ?? ''),
          DetailRow('Descrição', t.description),
          DetailRow('Tipo', _refName(ReferenceKind.taskType, t.taskTypeId)),
          DetailRow(
            'Técnico',
            _refName(ReferenceKind.orgUser, t.assignedUserId),
          ),
          DetailRow('Empresa', _refName(ReferenceKind.company, t.companyId)),
          DetailRow('Agendamento', _fmt(t.scheduledFor, t.scheduledAllDay)),
          if (t.notes.isNotEmpty) DetailRow('Observações', t.notes),
          const SizedBox(height: 16),
          Text('Alvos', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TaskTargetsField(
            clientId: t.clientId,
            targets: targets,
            onChanged: (_) {},
            readOnly: true,
          ),
          if (t.generatedOrderId != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Ver ordem gerada'),
              onPressed: () =>
                  context.push('/service-orders/${t.generatedOrderId}'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const Divider(height: 32),
          if (t.status == 'open') ...[
            FilledButton.icon(
              onPressed: _saving ? null : () => _generateOrder(t),
              icon: const Icon(Icons.assignment_add),
              label: const Text('Gerar ordem'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => _transition(t, 'complete'),
                    child: const Text('Concluir'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => _transition(t, 'cancel'),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ] else
            OutlinedButton(
              onPressed: _saving ? null : () => _transition(t, 'reopen'),
              child: const Text('Reabrir'),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _saving ? null : () => _delete(t),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir tarefa'),
          ),
        ],
      ),
    );
  }

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
      key: ValueKey('$kind:$value'),
      initialValue: value,
      isExpanded: true,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        helperText: enabled ? null : 'Sem permissão para trocar.',
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

  Widget _form(BuildContext context, LocalTask? existing) {
    if (existing == null && !_seededDefaults) {
      final me = ref.watch(identityProvider).value;
      if (me != null) {
        _companyId ??= me.primaryCompanyId;
        _assignedUserId ??= me.userId;
        _seededDefaults = true;
      }
    }
    // dados de referência: melhor esforço
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = ref.read(referenceDataRepositoryProvider);
      for (final k in ReferenceKind.values) {
        repo.refresh(k).ignore();
      }
    });

    final clients = ref.watch(clientListProvider).value ?? const [];
    final clientName = clients
        .where((c) => c.id == _clientId)
        .map((c) => c.name)
        .join();
    final canAssignCompany =
        ref.watch(permissionsProvider).value?.keys.contains(
          'task.assign_company',
        ) ??
        false;

    return Scaffold(
      appBar: brandAppBar(
        title: existing == null ? 'Nova tarefa' : 'Editar tarefa',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatória' : null,
              ),
              const SizedBox(height: 16),
              _referenceDropdown(
                kind: ReferenceKind.taskType,
                label: 'Tipo de tarefa (opcional)',
                value: _taskTypeId,
                onChanged: (v) => setState(() => _taskTypeId = v),
              ),
              const SizedBox(height: 16),
              _referenceDropdown(
                kind: ReferenceKind.orgUser,
                label: 'Técnico',
                value: _assignedUserId,
                onChanged: (v) => setState(() => _assignedUserId = v),
              ),
              const SizedBox(height: 16),
              _referenceDropdown(
                kind: ReferenceKind.company,
                label: 'Empresa',
                value: _companyId,
                enabled: canAssignCompany,
                onChanged: (v) => setState(() => _companyId = v),
              ),
              const SizedBox(height: 16),
              _scheduleFrame(context),
              const SizedBox(height: 16),
              // Cliente fica logo acima dos alvos; os alvos só aparecem depois
              // que há um cliente escolhido.
              if (existing == null && widget.presetClientId == null)
                ClientPickerField(
                  clientName: clientName,
                  onPick: () async {
                    final id = await pickClient(context);
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (!mounted) return;
                    if (id != null) {
                      setState(() {
                        _clientId = id;
                        _targets = [];
                      });
                    }
                  },
                )
              else if (clientName.isNotEmpty)
                DetailRow('Cliente', clientName),
              if (_clientId != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Alvos',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                TaskTargetsField(
                  clientId: _clientId,
                  targets: _targets,
                  onChanged: (t) => setState(() => _targets = t),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : () => _submit(existing),
                child: Text(_saving ? 'Salvando…' : 'Salvar'),
              ),
              if (existing != null)
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _viewMode = true;
                          _seeded = false;
                          _targetsSeeded = false;
                        }),
                  child: const Text('Cancelar'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scheduleFrame(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Agendada'),
            value: _showSchedule,
            onChanged: (v) => setState(() {
              _showSchedule = v;
              if (!v) _scheduledFor = null;
            }),
          ),
          if (_showSchedule) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Definir horário'),
              value: !_allDay,
              onChanged: (v) => setState(() => _allDay = !(v ?? true)),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _scheduledFor == null
                        ? 'Sem data'
                        : _fmt(_scheduledFor, _allDay),
                  ),
                ),
                TextButton(
                  onPressed: _pickSchedule,
                  child: Text(_scheduledFor == null ? 'Definir' : 'Reagendar'),
                ),
              ],
            ),
            Text(
              'Recorrência: em breve',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final base = (_scheduledFor ?? now).toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    if (date == null) return;
    if (_allDay) {
      setState(() => _scheduledFor = DateTime(date.year, date.month, date.day));
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    final t = time ?? TimeOfDay.fromDateTime(base);
    setState(
      () => _scheduledFor = DateTime(
        date.year,
        date.month,
        date.day,
        t.hour,
        t.minute,
      ),
    );
  }
}
