import 'package:flutter/material.dart';

/// Faixa abaixo da busca nas listas de Locais / Equipamentos quando elas estão
/// filtradas por um cliente (abertas pela tela do cliente). Mostra o nome do
/// cliente e um "✕" que limpa o filtro.
class ClientFilterBar extends StatelessWidget {
  const ClientFilterBar({super.key, required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: InputChip(
          label: Text('Cliente: $label'),
          onDeleted: onClear,
          deleteIcon: const Icon(Icons.close, size: 18),
        ),
      ),
    );
  }
}
