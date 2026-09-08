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
    // O recuo do teclado fica FORA do SafeArea (o teclado já cobre a barra de
    // navegação). Quando o teclado fecha, `viewInsets.bottom` volta a zero e o
    // SafeArea assume o recuo da barra — sem sobra dupla nem "buraco" entre o
    // último campo e o botão Salvar.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
      ),
    );
  }
}
