import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../../attachments/application/pending_uploads.dart';
import '../../clients/application/clients_provider.dart';
import '../../equipments/application/equipments_provider.dart';
import '../../locations/application/locations_provider.dart';
import '../application/service_orders_provider.dart';

const _statusLabels = {
  'draft': 'Rascunho',
  'open': 'Aberta',
  'in_progress': 'Em andamento',
  'completed': 'Concluída',
};

class ServiceOrderListScreen extends ConsumerStatefulWidget {
  const ServiceOrderListScreen({
    super.key,
    this.clientId,
    this.locationId,
    this.equipmentId,
  });

  /// Quando um deles é setado, a tela vira "Laudos" daquele registro: lista
  /// só as ordens ligadas a ele, com o nome no cabeçalho e botão de voltar.
  final String? clientId;
  final String? locationId;
  final String? equipmentId;

  bool get scoped =>
      clientId != null || locationId != null || equipmentId != null;

  @override
  ConsumerState<ServiceOrderListScreen> createState() =>
      _ServiceOrderListScreenState();
}

class _ServiceOrderListScreenState
    extends ConsumerState<ServiceOrderListScreen> {
  String? _status;

  bool _inScope(ServiceOrderWithClient e) {
    final o = e.order;
    return (widget.clientId == null || o.clientId == widget.clientId) &&
        (widget.locationId == null || o.locationId == widget.locationId) &&
        (widget.equipmentId == null || o.equipmentId == widget.equipmentId);
  }

  String? _scopeName() {
    if (widget.clientId != null) {
      return (ref.watch(clientListProvider).value ?? const [])
          .where((c) => c.id == widget.clientId)
          .map((c) => c.name)
          .join();
    }
    if (widget.locationId != null) {
      return (ref.watch(locationListProvider).value ?? const [])
          .where((l) => l.id == widget.locationId)
          .map((l) => l.name)
          .join();
    }
    if (widget.equipmentId != null) {
      return (ref.watch(equipmentListProvider).value ?? const [])
          .where((eq) => eq.id == widget.equipmentId)
          .map((eq) => eq.name)
          .join();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(serviceOrderListProvider);
    final scoped = widget.scoped;
    final total = scoped
        ? async.value?.where(_inScope).length
        : async.value?.length;
    final scopeName = scoped ? _scopeName() : null;
    final needsFilter = scoped || _status != null;

    return Scaffold(
      appBar: brandAppBar(
        title: scoped ? 'Laudos' : 'Ordens de serviço',
        count: total == null
            ? null
            : scoped
            ? '$total ${total == 1 ? 'laudo' : 'laudos'}'
            : '$total ${total == 1 ? 'ordem' : 'ordens'}',
        subtitle: scoped
            ? ((scopeName ?? '').isEmpty ? null : scopeName)
            : null,
        leading: scoped ? const BackButton() : null,
      ),
      body: SearchableListView<ServiceOrderWithClient>(
        async: async,
        onRefresh: () async {
          await ref.read(serviceOrderRepositoryProvider).refresh();
          await drainPendingUploads(ref);
        },
        hintText: 'Buscar por cliente ou motivo',
        emptyMessage: scoped
            ? 'Nenhum laudo relacionado.'
            : 'Nenhuma ordem ainda. Puxe pra baixo para sincronizar.',
        errorMessage: 'Não foi possível carregar as ordens.',
        searchText: (e) => '${e.clientName} ${e.order.reason}',
        extraFilter: needsFilter
            ? (e) =>
                  _inScope(e) &&
                  (_status == null || e.order.status == _status)
            : null,
        filterBar: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _StatusChip(
                label: 'Todas',
                selected: _status == null,
                onTap: () => setState(() => _status = null),
              ),
              for (final entry in _statusLabels.entries) ...[
                const SizedBox(width: 8),
                _StatusChip(
                  label: entry.value,
                  selected: _status == entry.key,
                  onTap: () => setState(
                    () => _status = _status == entry.key ? null : entry.key,
                  ),
                ),
              ],
            ],
          ),
        ),
        itemBuilder: (context, entry) {
          final order = entry.order;
          return ListTile(
            title: Text(entry.clientName),
            subtitle: Text(
              '${_statusLabels[order.status] ?? order.status}'
              '${order.reason.isNotEmpty ? ' · ${order.reason}' : ''}',
            ),
            trailing: switch (order.syncStatus) {
              'pending' => const Icon(
                Icons.cloud_upload_outlined,
                size: 17,
                color: BrandColor.blue,
              ),
              'conflict' => const Icon(
                Icons.warning_amber,
                size: 17,
                color: BrandColor.errorBar,
              ),
              _ => null,
            },
            onTap: () => context.push('/service-orders/${order.id}'),
          );
        },
      ),
      floatingActionButton: scoped
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/service-orders/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nova ordem'),
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? BrandColor.ink : BrandColor.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? BrandColor.ink : BrandColor.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 11,
              color: selected ? Colors.white : BrandColor.ink,
            ),
          ),
        ),
      ),
    );
  }
}
