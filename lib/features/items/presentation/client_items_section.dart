import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/child_list_section.dart';
import '../application/items_provider.dart';

/// Bloco "itens deste cliente" na tela do cliente — prévia + "Ver todos".
class ClientItemsSection extends ConsumerWidget {
  const ClientItemsSection({super.key, required this.clientId});

  final String clientId;

  static const _previewLimit = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [...ref.watch(itemsByClientProvider(clientId))]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final preview = items.take(_previewLimit).toList();
    final hasMore = items.length > _previewLimit;

    return ChildListSection(
      title: 'Itens',
      count: items.length,
      emptyMessage: 'Nenhum item cadastrado para este cliente.',
      addLabel: 'Novo item',
      onAdd: () => context.push('/items/new?clientId=$clientId'),
      seeAllLabel: hasMore ? 'Ver todos' : null,
      onSeeAll: hasMore
          ? () => context.push('/items?clientId=$clientId')
          : null,
      children: [
        for (final it in preview)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(it.name),
            subtitle: it.parentItemId != null
                ? const Text('subitem')
                : (it.city.isNotEmpty
                      ? Text('${it.city} - ${it.state}')
                      : null),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/items/${it.id}'),
          ),
      ],
    );
  }
}
