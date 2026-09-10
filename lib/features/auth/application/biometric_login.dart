import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// `true` quando o aparelho tem biometria OU bloqueio de tela (PIN/padrão/
/// senha) configurado — pré-requisito para o "entrar com digital".
final biometricAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricGateProvider).isSupported(),
);

/// Estado do "entrar com digital" (Configurações). Lê do armazenamento seguro
/// e é atualizado pelo próprio provider ao ligar/desligar.
class BiometricLoginPref extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(secureStoreProvider).readBiometricLoginEnabled();

  void setLocal(bool value) => state = AsyncData(value);
}

final biometricLoginEnabledProvider =
    AsyncNotifierProvider<BiometricLoginPref, bool>(BiometricLoginPref.new);
