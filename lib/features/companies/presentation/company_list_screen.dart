import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/searchable_list_view.dart';
import '../data/company_repository.dart';

const _kindLabels = {'legal': 'Pessoa jurídica', 'individual': 'Profissional'};

class CompanyListScreen extends ConsumerWidget {
  const CompanyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Empresas')),
      body: SearchableListView<Company>(
        async: ref.watch(companyListProvider),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/companies/new'),
        tooltip: 'Nova empresa',
        child: const Icon(Icons.add),
      ),
    );
  }
}
