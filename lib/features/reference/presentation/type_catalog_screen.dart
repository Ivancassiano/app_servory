import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../equipments/data/equipment_type_repository.dart';
import '../data/reference_repository.dart';
import '../data/type_catalog_repository.dart';

/// Cadastro dos catálogos auxiliares (tipos de equipamento / de ordem).
/// Abre num dos dois pelo `initial`.
class TypeCatalogScreen extends StatelessWidget {
  const TypeCatalogScreen({super.key, this.initial = TypeCatalog.equipmentType});

  final TypeCatalog initial;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initial == TypeCatalog.equipmentType ? 0 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tipos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Equipamentos'),
              Tab(text: 'Ordens de serviço'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CatalogTab(kind: TypeCatalog.equipmentType),
            _CatalogTab(kind: TypeCatalog.serviceOrderType),
          ],
        ),
      ),
    );
  }
}

class _CatalogTab extends ConsumerWidget {
  const _CatalogTab({required this.kind});

  final TypeCatalog kind;

  /// Atualiza também os seletores que consomem esses tipos por outro caminho.
  Future<void> _refreshPickers(WidgetRef ref) async {
    if (kind == TypeCatalog.equipmentType) {
      await ref.read(equipmentTypeRepositoryProvider).refresh();
    } else {
      await ref
          .read(referenceDataRepositoryProvider)
          .refresh(ReferenceKind.serviceOrderType);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(typeCatalogListProvider(kind));

    return Scaffold(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, ref),
        tooltip: 'Novo ${kind.singular.toLowerCase()}',
        child: const Icon(Icons.add),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Novo ${kind.singular.toLowerCase()}' : item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
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
        content: const Text('Não é possível se já houver registros usando este tipo.'),
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
