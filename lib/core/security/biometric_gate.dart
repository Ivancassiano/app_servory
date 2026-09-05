import 'package:local_auth/local_auth.dart';

/// Interface fina sobre `local_auth`, só para poder trocar por um dublê nos
/// testes (o plugin de verdade usa platform channel — não roda em
/// `flutter test`).
abstract class BiometricGate {
  /// Biometria OU o PIN/padrão/senha que o usuário já configurou no
  /// aparelho (`biometricOnly: false`) — é exatamente "PIN ou biometria" da
  /// spec §18.3, sem precisar construir um PIN próprio do app.
  Future<bool> authenticate(String localizedReason);

  /// Falso quando o aparelho não tem biometria nem PIN/padrão/senha
  /// configurado — nesse caso o app não oferece modo offline (spec §18.3,
  /// §24 "bloqueio do aplicativo por PIN/biometria").
  Future<bool> isSupported();
}

class LocalAuthBiometricGate implements BiometricGate {
  LocalAuthBiometricGate([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> authenticate(String localizedReason) {
    return _auth.authenticate(
      localizedReason: localizedReason,
      biometricOnly: false,
    );
  }

  @override
  Future<bool> isSupported() => _auth.isDeviceSupported();
}
