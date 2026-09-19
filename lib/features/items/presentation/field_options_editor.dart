import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../data/item_field_def_repository.dart' show FieldOptionInput;

/// Uma linha do editor de opções. `id == null` = opção ainda não salva.
class FieldOptionDraft {
  FieldOptionDraft({this.id, String label = '', this.active = true})
    : controller = TextEditingController(text: label);

  factory FieldOptionDraft.from(LocalItemFieldOption o) =>
      FieldOptionDraft(id: o.id, label: o.label, active: o.isActive);

  final String? id;
  final TextEditingController controller;
  bool active;
}

/// Valida e converte as linhas para o que o repositório envia. Linha nova em
/// branco é ignorada; opção já salva não pode ficar sem descrição (inative-a).
/// O campo lista precisa de ao menos uma opção ativa.
({List<FieldOptionInput>? options, String? error}) collectFieldOptions(
  List<FieldOptionDraft> drafts,
) {
  final out = <FieldOptionInput>[];
  for (final d in drafts) {
    final label = d.controller.text.trim();
    if (label.isEmpty) {
      if (d.id == null) continue;
      return (
        options: null,
        error: 'Preencha a descrição da opção ou inative-a.',
      );
    }
    out.add((id: d.id, label: label, active: d.active));
  }
  if (!out.any((o) => o.active)) {
    return (options: null, error: 'Informe ao menos uma opção ativa.');
  }
  return (options: out, error: null);
}

/// Opções de um campo do tipo lista: cada uma tem sua descrição e um botão para
/// inativar (ou remover, se ainda não foi salva); "Adicionar opção" abre uma
/// linha nova. Renomear mantém a opção — os itens que a usam não são afetados.
/// Inativar tira da seleção, mas os itens que já a têm continuam com ela.
///
/// Edita [drafts] no lugar; quem abre o editor lê a lista no salvar.
class FieldOptionsEditor extends StatefulWidget {
  const FieldOptionsEditor({super.key, required this.drafts, this.errorText});

  final List<FieldOptionDraft> drafts;
  final String? errorText;

  @override
  State<FieldOptionsEditor> createState() => _FieldOptionsEditorState();
}

class _FieldOptionsEditorState extends State<FieldOptionsEditor> {
  List<FieldOptionDraft> get _drafts => widget.drafts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Opções', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        for (var i = 0; i < _drafts.length; i++) _row(i),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(fontSize: 12, color: BrandColor.errorText),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _drafts.add(FieldOptionDraft())),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar opção'),
          ),
        ),
      ],
    );
  }

  Widget _row(int i) {
    final d = _drafts[i];
    final saved = d.id != null;
    return Padding(
      key: ValueKey(d),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: d.controller,
              enabled: d.active,
              decoration: InputDecoration(
                labelText: 'Descrição',
                helperText: d.active
                    ? null
                    : 'Inativa — não aparece na seleção',
              ),
            ),
          ),
          IconButton(
            tooltip: !saved
                ? 'Remover'
                : d.active
                ? 'Inativar'
                : 'Reativar',
            icon: Icon(
              !saved
                  ? Icons.close
                  : d.active
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () => setState(() {
              if (!saved) {
                _drafts.removeAt(i);
              } else {
                d.active = !d.active;
              }
            }),
          ),
        ],
      ),
    );
  }
}
