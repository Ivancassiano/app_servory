import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/searchable_list_view.dart';
import '../data/company_repository.dart';

const _kindLabels = {'legal': 'Pessoa jurídica', 'individual': 'Profissional'};

class CompanyListScreen extends ConsumerWidget {
  const CompanyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(companyListProvider);
    final total = async.value?.length;
    return Scaffold(
      appBar: brandAppBar(
        title: 'Empresas',
        count: total == null
            ? null
            : '$total ${total == 1 ? 'empresa' : 'empresas'}',
      ),
      body: SearchableListView<Company>(
        async: async,
        onRefresh: () => ref.read(companyRepositoryProvider).refresh(),
        hintText: 'Buscar empresa',
        emptyMessage: 'Nenhuma empresa cadastrada.',
        errorMessage: 'Não foi possível carregar as empresas.',
        searchText: (c) => '${c.name} ${c.legalName} ${c.taxId}',
        itemBuilder: (context, c) {
          final subtitle = [
            _kindLabels[c.kind] ?? c.kind,
            if (c.taxId.isNotEmpty) c.taxId,
          ].join(' · ');
          return ListTile(
            leading: CircleAvatar(
              child: Icon(c.hasLogo ? Icons.image_outlined : Icons.business),
            ),
            title: Text(c.name.isNotEmpty ? c.name : '(sem nome)'),
            subtitle: Text(subtitle),
            onTap: () => context.push('/companies/${c.id}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/companies/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova empresa'),
      ),
    );
  }
}
