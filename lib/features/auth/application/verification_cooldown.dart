import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Janela mínima entre reenvios do código de confirmação de e-mail.
const verificationResendCooldown = Duration(seconds: 30);

/// Momento do último reenvio. Em memória (sobrevive a sair e voltar da tela
/// de código na mesma execução) — o backend também rate-limita de verdade.
class VerificationResend extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void mark() => state = DateTime.now();

  /// Segundos restantes de cooldown (0 quando já pode reenviar).
  int remaining() {
    final last = state;
    if (last == null) return 0;
    final left =
        verificationResendCooldown.inSeconds -
        DateTime.now().difference(last).inSeconds;
    return left > 0 ? left : 0;
  }
}

final verificationResendProvider =
    NotifierProvider<VerificationResend, DateTime?>(VerificationResend.new);
