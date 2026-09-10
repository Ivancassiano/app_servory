import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Linha rótulo/valor do modo de leitura das telas de cadastro. Um registro
/// já salvo abre assim; o lápis no topo liga a edição.
class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {super.key});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final v = (value ?? '').trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 116,
            child: Text(label.toUpperCase(), style: BrandText.fieldLabel),
          ),
          Expanded(
            child: Text(v.isEmpty ? '—' : v, style: BrandText.fieldValue),
          ),
        ],
      ),
    );
  }
}

/// Bloco recolhível para os dados secundários (endereço, observações…) —
/// no modo de leitura eles ficam escondidos até o usuário tocar.
class DetailExpander extends StatefulWidget {
  const DetailExpander({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<DetailExpander> createState() => _DetailExpanderState();
}

class _DetailExpanderState extends State<DetailExpander> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  color: BrandColor.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (_open) ...widget.children,
      ],
    );
  }
}
