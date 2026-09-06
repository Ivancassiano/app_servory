import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../data/qr_mapper.dart';
import '../data/qr_repository.dart';

/// Seção "Etiqueta" das telas de detalhe (cliente / local / equipamento).
/// Fatia 3a: só leitura — mostra o código público da etiqueta ativa, ou
/// "Nenhuma etiqueta". Vincular / substituir / desativar entram na 3b.
class QrLabelSection extends ConsumerWidget {
  const QrLabelSection({super.key, required this.target});

  final QrTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeQrCodeProvider(target));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Etiqueta', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => Text(
            'Não foi possível carregar a etiqueta.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (code) => code == null
              ? const _NoLabel()
              : _LabelCard(code: code),
        ),
      ],
    );
  }
}

class _NoLabel extends StatelessWidget {
  const _NoLabel();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.qr_code_2_outlined),
        title: Text('Nenhuma etiqueta'),
        subtitle: Text('Este registro ainda não tem uma etiqueta vinculada.'),
      ),
    );
  }
}

class _LabelCard extends StatelessWidget {
  const _LabelCard({required this.code});

  final LocalQrCode code;

  @override
  Widget build(BuildContext context) {
    final pending = code.syncStatus == 'pending';
    final conflict = code.syncStatus == 'conflict';
    final display = code.publicCode ?? '(código pendente de sincronização)';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.qr_code_2),
        title: SelectableText(
          display,
          style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Text(
          conflict
              ? 'Conflito: esta etiqueta já está em uso em outro registro. '
                    'É necessário substituir a etiqueta física.'
              : pending
              ? 'Vínculo pendente de sincronização.'
              : 'Etiqueta ativa.',
          style: conflict
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
        trailing: code.publicCode == null
            ? null
            : IconButton(
                tooltip: 'Copiar código',
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code.publicCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado.')),
                  );
                },
              ),
      ),
    );
  }
}
