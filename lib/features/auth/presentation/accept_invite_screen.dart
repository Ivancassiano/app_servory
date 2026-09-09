import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../application/session_controller.dart';
import '../domain/password_policy.dart';
import 'password_requirements.dart';

/// Aceitar um convite: o convidado recebe um código por e-mail e o usa aqui
/// junto com nome e senha. Ao confirmar, entra direto na organização.
class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key});

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final code = _codeController.text
          .replaceAll(RegExp('[^A-Za-z0-9]'), '')
          .toUpperCase();
      await ref
          .read(sessionControllerProvider.notifier)
          .acceptInvite(
            code: code,
            name: _nameController.text.trim(),
            password: _passwordController.text,
          );
      TextInput.finishAutofillContext();
      // Sucesso: a mudança de sessão leva o router para a home.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.friendlyMessage);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Não foi possível aceitar o convite agora.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: brandAppBar(title: 'Aceitar convite'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Digite o código do e-mail de convite e defina seu acesso. '
                        'Se você já tem conta, use a mesma senha.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        maxLength: 12,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp('[A-Za-z0-9 -]'),
                          ),
                          TextInputFormatter.withFunction(
                            (_, n) => n.copyWith(text: n.text.toUpperCase()),
                          ),
                        ],
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Mono',
                          fontSize: 18,
                          letterSpacing: 3,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Código do convite',
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o código.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Seu nome',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe seu nome.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => PasswordPolicy.isValid(v ?? '')
                            ? null
                            : PasswordPolicy.requirementMessage,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      PasswordRequirements(
                        controller: _passwordController,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Entrar na organização'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : () => context.go('/login'),
                        child: const Text('Voltar ao login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
