import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Aviso de conflito de versão (`VERSION_CONFLICT`, spec §12 — "a primeira
/// confirmação do servidor vence"). Aparece no lugar do erro genérico quando
/// outra pessoa alterou o registro enquanto o usuário editava: oferece
/// recarregar os dados do servidor para o usuário refazer as alterações.
class ConflictNotice extends StatelessWidget {
  const ConflictNotice({
    super.key,
    required this.onReload,
    this.reloading = false,
  });

  final VoidCallback onReload;
  final bool reloading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrandColor.errorBg,
        border: Border(left: BorderSide(color: BrandColor.errorBar, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Outra pessoa alterou este registro enquanto você editava.',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: BrandColor.errorText,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Recarregue os dados do servidor e refaça suas alterações.',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 12,
              height: 1.4,
              color: BrandColor.errorText,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: reloading ? null : onReload,
              child: reloading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Recarregar do servidor'),
            ),
          ),
        ],
      ),
    );
  }
}
