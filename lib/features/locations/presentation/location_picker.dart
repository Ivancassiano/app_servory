import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../clients/presentation/client_picker.dart' show accentFold;
import '../application/locations_provider.dart';
import '../data/location_mapper.dart';

/// Bottom sheet de busca + seleção de um local do cliente. Retorna o id
/// escolhido, ou a string vazia para "nenhum local".
Future<String?> pickLocation(
  BuildContext context, {
  required String clientId,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _LocationPickerSheet(clientId: clientId),
);

class _LocationPickerSheet extends ConsumerStatefulWidget {
  const _LocationPickerSheet({required this.clientId});
  final String clientId;

  @override
  ConsumerState<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  String _q = '';
  final _newName = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _newName.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _newName.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    try {
      final id = await ref
          .read(locationRepositoryProvider)
          .create(
            clientId: widget.clientId,
            fields: LocationFields(name: name),
          );
      if (mounted) Navigator.of(context).pop(id);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locations =
        ref
            .watch(locationsByClientProvider(widget.clientId))
            .where(
              (l) =>
                  _q.isEmpty ||
                  accentFold('${l.name} ${locationAddressLine(l)}')
                      .contains(accentFold(_q)),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return FormSheet(
      title: 'Local',
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Pesquise um local',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 8),
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.block),
          title: const Text('Sem local'),
          onTap: () => Navigator.of(context).pop(''),
        ),
        for (final l in locations)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(_label(l)),
            onTap: () => Navigator.of(context).pop(l.id),
          ),
        const Divider(),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newName,
                decoration: const InputDecoration(labelText: 'Novo local'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _creating ? null : _create,
              child: const Text('Criar'),
            ),
          ],
        ),
      ],
    );
  }

  String _label(LocalLocation l) {
    final addr = locationAddressLine(l);
    if (l.name.isEmpty) return addr.isEmpty ? 'Local sem nome' : addr;
    return addr.isEmpty ? l.name : '${l.name} — $addr';
  }
}

/// Campo "Local" de um formulário: mostra o local escolhido + botão.
class LocationPickerField extends StatelessWidget {
  const LocationPickerField({
    super.key,
    required this.locationLabel,
    required this.onPick,
  });

  final String? locationLabel;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final chosen = locationLabel != null && locationLabel!.isNotEmpty;
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Local (opcional)'),
      child: Row(
        children: [
          Expanded(
            child: Text(
              chosen ? locationLabel! : 'Sem local',
              style: chosen
                  ? null
                  : TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          TextButton(
            onPressed: onPick,
            child: Text(chosen ? 'Trocar' : 'Escolher local'),
          ),
        ],
      ),
    );
  }
}
