import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Filtro rápido de situação (ativo/inativo) das listas de cadastro.
/// `ativos` é sempre o padrão.
enum ActiveFilter { ativos, inativos, todos }

extension ActiveFilterX on ActiveFilter {
  /// `true` se um registro com esse `isActive` passa pelo filtro.
  bool accepts(bool isActive) => switch (this) {
    ActiveFilter.ativos => isActive,
    ActiveFilter.inativos => !isActive,
    ActiveFilter.todos => true,
  };

  String get label => switch (this) {
    ActiveFilter.ativos => 'Ativos',
    ActiveFilter.inativos => 'Inativos',
    ActiveFilter.todos => 'Todos',
  };
}

/// Barra de chips "Ativos / Inativos / Todos" para o slot `filterBar` do
/// [SearchableListView].
class ActiveFilterBar extends StatelessWidget {
  const ActiveFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ActiveFilter value;
  final ValueChanged<ActiveFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final f in ActiveFilter.values) ...[
            if (f != ActiveFilter.values.first) const SizedBox(width: 8),
            _Chip(
              label: f.label,
              selected: value == f,
              onTap: () => onChanged(f),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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

/// Selo compacto "Ativo" (discreto) / "Inativo" (destaque) ao lado de um item
/// da lista.
class ActiveBadge extends StatelessWidget {
  const ActiveBadge({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: active ? BrandColor.border : BrandColor.errorBar,
        ),
        color: active ? BrandColor.surface : BrandColor.errorBg,
      ),
      child: Text(
        active ? 'Ativo' : 'Inativo',
        style: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 10,
          color: active ? BrandColor.textTertiary : BrandColor.errorText,
        ),
      ),
    );
  }
}
