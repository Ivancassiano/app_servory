import 'package:flutter/material.dart';

/// Offline por mais de 7 dias desde a última validação com o servidor
/// (spec §18.3). Os dados locais continuam intactos — só o acesso fica
/// bloqueado até reconectar; não é um logout.
class OfflineExpiredScreen extends StatelessWidget {
  const OfflineExpiredScreen({super.key});

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
                  Icons.wifi_off,
                  size: 56,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sua sessão offline expirou',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Já faz mais de 7 dias desde a última vez que este aparelho '
                  'confirmou a sessão com o servidor. Seus dados salvos continuam '
                  'aqui — conecte-se à internet para continuar.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
