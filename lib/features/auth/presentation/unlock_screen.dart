import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../application/app_lock_controller.dart';

/// Sessão offline válida, mas o app precisa confirmar que é você antes de
/// mostrar os dados em cache (spec §18.3). Dispara a checagem sozinho ao
/// abrir a tela — o botão é só para repetir se cancelar/falhar.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  bool? _supported;
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndPrompt());
  }

  Future<void> _checkAndPrompt() async {
    final gate = ref.read(biometricGateProvider);
    final supported = await gate.isSupported();
    if (!mounted) return;
    setState(() => _supported = supported);
    if (supported) await _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _authenticating = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(biometricGateProvider)
          .authenticate(
            'Autentique-se para continuar usando o ServiceLog offline',
          );
      if (!mounted) return;
      if (ok) {
        ref.read(appLockControllerProvider.notifier).unlock();
      } else {
        setState(() => _error = 'Não foi possível confirmar sua identidade.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível confirmar sua identidade.');
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Você está offline',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_supported == false) ...[
                  const Text(
                    'Este aparelho não tem biometria nem PIN/padrão configurado. '
                    'Conecte-se à internet para continuar usando o ServiceLog.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Text(
                    'Confirme sua identidade para ver os dados salvos neste aparelho.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: _authenticating ? null : _authenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(
                      _authenticating ? 'Confirmando...' : 'Desbloquear',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
