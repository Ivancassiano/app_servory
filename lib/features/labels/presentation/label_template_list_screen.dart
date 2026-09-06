import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/label_template_repository.dart';

class LabelTemplateListScreen extends ConsumerWidget {
  const LabelTemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(labelTemplateListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Modelos de etiqueta')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(labelTemplateRepositoryProvider).refresh(),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('Não foi possível carregar.\n$e')),
              ),
            ],
          ),
          data: (templates) {
            if (templates.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhum modelo. Toque em + para criar um texto de '
                        'complemento reutilizável na folha de etiquetas.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: templates.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = templates[i];
                return ListTile(
                  title: Text(t.name.isNotEmpty ? t.name : 'Sem nome'),
                  subtitle: Text(
                    t.body.replaceAll('\n', ' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/label-templates/${t.id}'),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/label-templates/new'),
        tooltip: 'Novo modelo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
