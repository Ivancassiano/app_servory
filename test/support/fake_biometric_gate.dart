import 'package:servory/core/security/biometric_gate.dart';

/// Dublê do [BiometricGate] para os testes de widget/unidade (o `local_auth`
/// de verdade usa platform channel).
class FakeBiometricGate implements BiometricGate {
  FakeBiometricGate({this.supported = false, this.authResult = true});

  bool supported;
  bool authResult;
  int authCalls = 0;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> authenticate(String localizedReason) async {
    authCalls++;
    return authResult;
  }
}
