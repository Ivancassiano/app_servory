import 'package:flutter/material.dart';

/// Moldura padrão de um formulário em bottom sheet (cadastro/edição rápida):
/// título, corpo rolável e recuo que acompanha o teclado. Os cadastros do
/// app abrem por aqui — nunca por `AlertDialog` (esse fica só para
/// confirmações do tipo sim/não). Use com
/// `showModalBottomSheet(isScrollControlled: true, builder: ...)`.
class FormSheet extends StatelessWidget {
  const FormSheet({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom:
            16 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
