import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../items/data/item_type_repository.dart';
import '../data/reference_repository.dart';
import '../data/type_catalog_repository.dart';

/// Cadastro de um catálogo auxiliar (tipos de equipamento **ou** tipos de ordem
/// de serviço — nunca os dois na mesma tela). Acessada por Configurações →
/// Catálogos.
class TypeCatalogScreen extends ConsumerWidget {
  const TypeCatalogScreen({super.key, required this.kind});

  final TypeCatalog kind;

  /// Atualiza também os seletores que consomem esses tipos por outro caminho.
  Future<void> _refreshPickers(WidgetRef ref) async {
    if (kind == TypeCatalog.itemType) {
      await ref.read(itemTypeRepositoryProvider).refresh();
    } else {
      await ref
          .read(referenceDataRepositoryProvider)
          .refresh(ReferenceKind.serviceOrderType);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(typeCatalogListProvider(kind));
    final total = async.value?.length;

    return Scaffold(
      appBar: brandAppBar(
        title: kind.title,
        count: total == null
            ? null
            : '$total ${total == 1 ? 'tipo' : 'tipos'}',
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(typeCatalogRepositoryProvider).refresh(kind),
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
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Nenhum tipo cadastrado.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = items[i];
                return ListTile(
                  title: Text(t.name.isNotEmpty ? t.name : 'Sem nome'),
                  subtitle: t.description.isEmpty ? null : Text(t.description),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, ref, t),
                  ),
                  onTap: () => _edit(context, ref, item: t),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: Text('Novo ${kind.singular.toLowerCase()}'),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    TypeCatalogItem? item,
  }) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FormSheet(
        title: item == null
            ? 'Novo ${kind.singular.toLowerCase()}'
            : item.name,
        children: [
          TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;

    final repo = ref.read(typeCatalogRepositoryProvider);
    try {
      if (item == null) {
        await repo.create(
          kind,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
        );
      } else {
        await repo.update(
          kind,
          item.id,
          version: item.version,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
        );
      }
      await _refreshPickers(ref);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.friendlyMessage)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar.')),
        );
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TypeCatalogItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir "${item.name}"?'),
        content: const Text(
          'Não é possível se já houver registros usando este tipo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(typeCatalogRepositoryProvider).delete(kind, item.id);
      await _refreshPickers(ref);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'CONFLICT' || e.statusCode == 409
                  ? 'Este tipo está em uso e não pode ser excluído.'
                  : e.friendlyMessage,
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir.')),
        );
      }
    }
  }
}
