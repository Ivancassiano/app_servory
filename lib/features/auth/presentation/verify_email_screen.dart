import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../application/session_controller.dart';
import '../application/verification_cooldown.dart';

/// Confirma o e-mail pelo código recebido. Ao dar certo, o backend devolve a
/// sessão e o roteador leva para a home automaticamente.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _errorMessage;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Retoma o cooldown se o usuário já reenviou há pouco (saiu e voltou).
    final left = ref.read(verificationResendProvider.notifier).remaining();
    if (left > 0) _startCooldown(left);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    setState(() => _resendCooldown = seconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Informe o código.');
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .verifyEmail(code: code);
      // Sucesso: a mudança de sessão dispara o redirect do router para a home.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.friendlyMessage);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Não foi possível confirmar agora. Tente de novo.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    ref.read(verificationResendProvider.notifier).mark();
    _startCooldown(verificationResendCooldown.inSeconds);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .resendVerification(widget.email);
      messenger.showSnackBar(
        const SnackBar(content: Text('Código reenviado. Confira seu e-mail.')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.friendlyMessage)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível reenviar agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: brandAppBar(title: 'Confirme seu e-mail'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.email.isEmpty
                        ? 'Enviamos um código de 8 caracteres para o seu e-mail. '
                              'Digite-o abaixo para ativar sua conta.'
                        : 'Enviamos um código de 8 caracteres para '
                              '${widget.email}. Digite-o abaixo para ativar sua conta.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    maxLength: 12, // 8 + espaço/hífen colados; o backend normaliza
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
                      labelText: 'Código de confirmação',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _confirm(),
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
                    onPressed: _busy ? null : _confirm,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirmar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: (_busy || _resendCooldown > 0) ? null : _resend,
                    child: Text(
                      _resendCooldown > 0
                          ? 'Reenviar código (${_resendCooldown}s)'
                          : 'Reenviar código',
                    ),
                  ),
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
    );
  }
}
