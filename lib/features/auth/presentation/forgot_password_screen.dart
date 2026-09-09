import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../application/session_controller.dart';
import '../domain/password_policy.dart';
import 'password_requirements.dart';

enum _Phase { email, code, done }

/// "Esqueci minha senha": pede o e-mail, envia um código, e troca a senha
/// pelo código. Ao final o usuário volta para o login e entra com a nova
/// senha (o backend revoga as sessões).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.email});

  /// Pré-preenche o e-mail quando veio da tela de login.
  final String? email;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Phase _phase = _Phase.email;
  bool _busy = false;
  bool _obscure = true;
  String? _errorMessage;
  int _resendCooldown = 0;
  Timer? _timer;

  static const _resendCooldownSeconds = 30;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) _emailController.text = widget.email!;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();

  void _startCooldown() {
    setState(() => _resendCooldown = _resendCooldownSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (!resend && !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).forgotPassword(_email);
      if (!mounted) return;
      setState(() => _phase = _Phase.code);
      _startCooldown();
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.friendlyMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Não foi possível enviar o código agora.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    // Aceita "abcd-2345" / "ABCD 2345" e manda limpo (o backend também
    // normaliza, mas assim o erro fica claro se o código estiver errado).
    final code = _codeController.text
        .replaceAll(RegExp('[^A-Za-z0-9]'), '')
        .toUpperCase();
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .resetPassword(code: code, newPassword: _passwordController.text);
      if (mounted) setState(() => _phase = _Phase.done);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.friendlyMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Não foi possível redefinir a senha agora.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: brandAppBar(title: 'Esqueci minha senha'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: switch (_phase) {
                _Phase.email => _emailForm(),
                _Phase.code => _codeForm(),
                _Phase.done => _doneView(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Informe o e-mail da sua conta. Vamos enviar um código para você '
            'definir uma nova senha.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'E-mail'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe o e-mail.';
              if (!v.contains('@')) return 'E-mail inválido.';
              return null;
            },
            onFieldSubmitted: (_) => _sendCode(),
          ),
          _errorText(),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _sendCode,
            child: _busy ? const _Spinner() : const Text('Enviar código'),
          ),
        ],
      ),
    );
  }

  Widget _codeForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enviamos um código para $_email. Digite-o abaixo e escolha uma '
            'nova senha.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codeController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            maxLength: 12,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9 -]')),
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
              labelText: 'Código do e-mail',
              counterText: '',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o código.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Nova senha',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => PasswordPolicy.isValid(v ?? '')
                ? null
                : PasswordPolicy.requirementMessage,
          ),
          PasswordRequirements(controller: _passwordController),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscure,
            decoration: const InputDecoration(labelText: 'Confirmar senha'),
            validator: (v) => (v != _passwordController.text)
                ? 'As senhas não conferem.'
                : null,
            onFieldSubmitted: (_) => _reset(),
          ),
          _errorText(),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _reset,
            child: _busy ? const _Spinner() : const Text('Redefinir senha'),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _busy || _resendCooldown > 0
                  ? null
                  : () => _sendCode(resend: true),
              child: Text(
                _resendCooldown > 0
                    ? 'Reenviar código em ${_resendCooldown}s'
                    : 'Reenviar código',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doneView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          'Senha redefinida. Entre com a nova senha.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go('/login'),
          child: const Text('Ir para o login'),
        ),
      ],
    );
  }

  Widget _errorText() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _errorMessage!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
