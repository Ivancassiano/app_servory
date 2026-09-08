import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../application/clients_provider.dart';

/// minúsculas + sem acento (mesma lógica de SearchableListView).
String accentFold(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i == -1 ? ch : to[i]);
  }
  return b.toString();
}

/// Bottom sheet de busca + seleção de cliente. Retorna o id escolhido.
/// Usado no form da ordem de serviço e no cadastro de item.
Future<String?> pickClient(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ClientPickerSheet(),
    );

class _ClientPickerSheet extends ConsumerStatefulWidget {
  const _ClientPickerSheet();

  @override
  ConsumerState<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends ConsumerState<_ClientPickerSheet> {
  String _q = '';
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final clients =
        (ref.watch(clientListProvider).value ?? const <LocalClient>[])
            .where(
              (c) => _q.isEmpty || accentFold(c.name).contains(accentFold(_q)),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cliente',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Pesquise o cliente',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _q = v),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: clients.length,
                    itemBuilder: (_, i) {
                      final c = clients[i];
                      final sel = c.id == _selected;
                      return ListTile(
                        dense: true,
                        selected: sel,
                        title: Text(c.name),
                        trailing: sel ? const Icon(Icons.check) : null,
                        onTap: () => setState(() => _selected = c.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  child: const Text('Selecionar cliente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo "Cliente" de um formulário: mostra o nome escolhido + botão que
/// abre o [pickClient].
class ClientPickerField extends StatelessWidget {
  const ClientPickerField({
    super.key,
    required this.clientName,
    required this.onPick,
  });

  final String? clientName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final chosen = clientName != null && clientName!.isNotEmpty;
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Cliente'),
      child: Row(
        children: [
          Expanded(
            child: Text(
              chosen ? clientName! : 'Nenhum cliente',
              style: chosen
                  ? null
                  : TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          TextButton(
            onPressed: onPick,
            child: Text(chosen ? 'Trocar' : 'Selecionar cliente'),
          ),
        ],
      ),
    );
  }
}
