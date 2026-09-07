import 'package:flutter/material.dart';

/// Bloco "filhos de um registro" — lista de locais na tela do cliente,
/// de equipamentos na tela do local. Puramente apresentacional: quem chama
/// já filtrou a lista pelo pai.
class ChildListSection extends StatelessWidget {
  const ChildListSection({
    super.key,
    required this.title,
    required this.count,
    required this.children,
    required this.emptyMessage,
    required this.addLabel,
    required this.onAdd,
    this.seeAllLabel,
    this.onSeeAll,
  });

  final String title;
  final int? count;
  final List<Widget> children;
  final String emptyMessage;
  final String addLabel;
  final VoidCallback onAdd;

  /// Quando setados, mostra um "Ver todos (N)" abaixo da lista (a lista aqui
  /// é só uma prévia).
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            count == null ? title : '$title ($count)',
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(emptyMessage),
          )
        else
          Column(children: children),
        if (seeAllLabel != null && onSeeAll != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onSeeAll, child: Text(seeAllLabel!)),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(addLabel),
        ),
      ],
    );
  }
}
