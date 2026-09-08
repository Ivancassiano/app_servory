import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../application/items_provider.dart';

String _pad2(int n) => n.toString().padLeft(2, '0');

/// Renderiza os campos personalizados aplicáveis a um item (globais + do tipo
/// escolhido) e devolve os valores digitados via [onChanged]. Sem estado de
/// submit próprio — a tela do item chama `repo.setValues` no salvar.
class ItemCustomFieldsForm extends ConsumerStatefulWidget {
  const ItemCustomFieldsForm({
    super.key,
    required this.itemTypeId,
    required this.initial,
    required this.onChanged,
  });

  /// Tipo do item escolhido no form (muda o conjunto de campos).
  final String? itemTypeId;

  /// Valores já gravados, por `field_def_id`.
  final Map<String, TypedFieldValue> initial;

  final ValueChanged<Map<String, TypedFieldValue>> onChanged;

  @override
  ConsumerState<ItemCustomFieldsForm> createState() =>
      _ItemCustomFieldsFormState();
}

class _ItemCustomFieldsFormState extends ConsumerState<ItemCustomFieldsForm> {
  final _values = <String, TypedFieldValue>{};
  final _textControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _values.addAll(widget.initial);
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _set(String defId, TypedFieldValue v) {
    setState(() {
      if (v.isEmpty) {
        _values.remove(defId);
      } else {
        _values[defId] = v;
      }
    });
    widget.onChanged(Map.of(_values));
  }

  TextEditingController _ctrl(String defId, String initial) => _textControllers
      .putIfAbsent(defId, () => TextEditingController(text: initial));

  @override
  Widget build(BuildContext context) {
    final defs = ref.watch(itemFieldDefsForTypeProvider(widget.itemTypeId));
    if (defs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Campos personalizados',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final d in defs) ...[const SizedBox(height: 16), _field(d)],
      ],
    );
  }

  Widget _field(LocalItemFieldDef d) {
    final cur = _values[d.id];
    final label = d.required ? '${d.label} *' : d.label;
    switch (d.dataType) {
      case 'boolean':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: cur?.boolean ?? false,
          onChanged: (v) => _set(d.id, TypedFieldValue(boolean: v)),
        );
      case 'number':
        return TextFormField(
          controller: _ctrl(d.id, cur?.number?.toString() ?? ''),
          decoration: InputDecoration(labelText: label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _set(
            d.id,
            TypedFieldValue(number: double.tryParse(v.replaceAll(',', '.'))),
          ),
          validator: (v) => d.required && (v == null || v.trim().isEmpty)
              ? 'Obrigatório'
              : null,
        );
      case 'date':
      case 'datetime':
        final withTime = d.dataType == 'datetime';
        final dt = cur?.datetime?.toLocal();
        final text = dt == null
            ? ''
            : withTime
            ? '${_pad2(dt.day)}/${_pad2(dt.month)}/${dt.year} ${_pad2(dt.hour)}:${_pad2(dt.minute)}'
            : '${_pad2(dt.day)}/${_pad2(dt.month)}/${dt.year}';
        return InkWell(
          onTap: () async {
            final now = DateTime.now();
            final base = cur?.datetime?.toLocal() ?? now;
            final day = await showDatePicker(
              context: context,
              initialDate: base,
              firstDate: DateTime(now.year - 30),
              lastDate: DateTime(now.year + 30),
            );
            if (day == null) return;
            if (!withTime) {
              _set(d.id, TypedFieldValue(datetime: DateTime(day.year, day.month, day.day)));
              return;
            }
            if (!mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(base),
            );
            final t = time ?? TimeOfDay.fromDateTime(base);
            _set(
              d.id,
              TypedFieldValue(
                datetime: DateTime(
                  day.year,
                  day.month,
                  day.day,
                  t.hour,
                  t.minute,
                ),
              ),
            );
          },
          child: InputDecorator(
            decoration: InputDecoration(labelText: label),
            child: Text(text.isEmpty ? 'Selecionar…' : text),
          ),
        );
      case 'select':
        final options =
            ref.watch(itemFieldOptionsProvider(d.id)).value ??
            const <LocalItemFieldOption>[];
        return DropdownButtonFormField<String>(
          initialValue: cur?.text,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o.value, child: Text(o.label)),
          ],
          onChanged: (v) => _set(d.id, TypedFieldValue(text: v)),
          validator: (v) =>
              d.required && (v == null || v.isEmpty) ? 'Obrigatório' : null,
        );
      default: // text
        return TextFormField(
          controller: _ctrl(d.id, cur?.text ?? ''),
          decoration: InputDecoration(labelText: label),
          onChanged: (v) =>
              _set(d.id, TypedFieldValue(text: v.trim().isEmpty ? null : v)),
          validator: (v) => d.required && (v == null || v.trim().isEmpty)
              ? 'Obrigatório'
              : null,
        );
    }
  }
}
