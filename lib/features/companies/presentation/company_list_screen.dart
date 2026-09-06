import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/company_repository.dart';

const _kindLabels = {'legal': 'Pessoa jurídica', 'individual': 'Profissional'};

class CompanyListScreen extends ConsumerWidget {
  const CompanyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(companyListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Empresas')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(companyRepositoryProvider).refresh(),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Não foi possível carregar as empresas.\n$e',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          data: (companies) {
            if (companies.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Nenhuma empresa cadastrada.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: companies.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = companies[i];
                final subtitle = [
                  _kindLabels[c.kind] ?? c.kind,
                  if (c.taxId.isNotEmpty) c.taxId,
                ].join(' · ');
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      c.hasLogo ? Icons.image_outlined : Icons.business,
                    ),
                  ),
                  title: Text(c.name.isNotEmpty ? c.name : '(sem nome)'),
                  subtitle: Text(subtitle),
                  onTap: () => context.push('/companies/${c.id}'),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/companies/new'),
        tooltip: 'Nova empresa',
        child: const Icon(Icons.add),
      ),
    );
  }
}
