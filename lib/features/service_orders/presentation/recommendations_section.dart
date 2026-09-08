import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/form_sheet.dart';
import '../data/recommendation_repository.dart';

const _priorityLabels = {'low': 'Baixa', 'medium': 'Média', 'high': 'Alta'};
const _recStatusLabels = {
  'open': 'Em aberto',
  'addressed': 'Resolvida',
  'dismissed': 'Descartada',
};

/// Lista de recomendações — local-first (§8.4), sincroniza como as peças.
/// `serviceOrderItemId` nulo = as recomendações **gerais** da ordem; setado =
/// só as daquele item (e novas ficam vinculadas a ele). Editar exige a ordem
/// num status editável.
class RecommendationsSection extends ConsumerWidget {
  const RecommendationsSection({
    super.key,
    required this.serviceOrderId,
    this.serviceOrderItemId,
  });

  final String serviceOrderId;
  final String? serviceOrderItemId;

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
            'Não foi possível carregar as recomendações.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (all) {
            final recs = [
              for (final r in all)
                if (r.serviceOrderItemId == serviceOrderItemId) r,
            ];
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
                            .delete(serviceOrderId, r.id, version: r.version),
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
    LocalServiceOrderRecommendation? rec,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RecommendationFormSheet(
        serviceOrderId: serviceOrderId,
        serviceOrderItemId: serviceOrderItemId,
        rec: rec,
      ),
    );
  }
}

class _RecommendationFormSheet extends ConsumerStatefulWidget {
  const _RecommendationFormSheet({
    required this.serviceOrderId,
    required this.serviceOrderItemId,
    this.rec,
  });

  final String serviceOrderId;
  final String? serviceOrderItemId;
  final LocalServiceOrderRecommendation? rec;

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
          serviceOrderItemId: widget.serviceOrderItemId,
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
              'Não foi possível salvar. A ordem precisa estar num status editável.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: widget.rec == null ? 'Nova recomendação' : 'Editar recomendação',
      children: [
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
    );
  }
}
