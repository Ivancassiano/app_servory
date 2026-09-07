import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Faixa abaixo da busca nas listas de Locais / Equipamentos quando elas estão
/// filtradas por um cliente (abertas pela tela do cliente). Mostra o nome do
/// cliente e um "✕" que limpa o filtro. Fundo escuro pra ler como "filtro
/// ativo".
class ClientFilterBar extends StatelessWidget {
  const ClientFilterBar({super.key, required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: const BoxDecoration(color: BrandColor.ink),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cliente: $label',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onClear,
            tooltip: 'Limpar filtro',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
