import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/password_policy.dart';

/// Checklist ao vivo das regras de senha ([PasswordPolicy]), para exibir logo
/// abaixo do campo. Observa [controller] e se redesenha a cada tecla — a tela
/// não precisa de `setState`.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final rules = PasswordPolicy.evaluate(value.text);
        return Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in rules)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        r.satisfied
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 16,
                        color: r.satisfied
                            ? BrandColor.blue
                            : BrandColor.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: r.satisfied
                              ? BrandColor.textSecondary
                              : BrandColor.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
