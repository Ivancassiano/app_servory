import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Guarda a sessão (tokens) e o `device.id` persistente.
///
/// No mobile isso usa Keychain/Keystore; no Chrome usa IndexedDB protegido
/// por uma chave gerenciada pelo WebCrypto do navegador — não é o banco
/// local criptografado da spec §18 (que só existe em iOS/Android, quando o
/// app ganhar SQLite/Drift), mas é suficiente para o modo "sempre online" do
/// Chrome, que não guarda dado de negócio localmente, só a sessão.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kOrganizationId = 'organization_id';
  static const _kUserId = 'user_id';
  static const _kDeviceId = 'device_id';
  static const _kLastOnlineValidationAt = 'last_online_validation_at';
  static const _kBiometricLoginEnabled = 'biometric_login_enabled';
  static const _kSavedEmail = 'saved_email';
  static const _kSavedPassword = 'saved_password';
  static const _kLastEmail = 'last_email';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String organizationId,
    required String userId,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kOrganizationId, value: organizationId),
      _storage.write(key: _kUserId, value: userId),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<String?> readOrganizationId() => _storage.read(key: _kOrganizationId);
  Future<String?> readUserId() => _storage.read(key: _kUserId);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kOrganizationId),
      _storage.delete(key: _kUserId),
    ]);
  }

  /// Timestamp da última vez que a sessão foi confirmada com o servidor
  /// (login ou refresh bem-sucedido) — usado para o prazo de sessão offline
  /// de 7 dias (spec §18.3). Sobrevive ao `clearSession` propositalmente? Não:
  /// é parte da sessão, some junto no logout.
  Future<void> saveLastOnlineValidation(DateTime at) => _storage.write(
    key: _kLastOnlineValidationAt,
    value: at.toIso8601String(),
  );

  Future<DateTime?> readLastOnlineValidation() async {
    final raw = await _storage.read(key: _kLastOnlineValidationAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Chave de criptografia do banco local desta organização (spec §18.1),
  /// 256 bits em hexadecimal — gerada uma vez por [DbKeyStore], nunca
  /// enviada ao servidor. Fica fora de `clearSession`: a chave sobrevive a
  /// um logout (os dados locais continuam existindo até o usuário logar de
  /// novo); só é apagada se o app inteiro for desinstalado.
  Future<String?> readDbKey(String organizationId) =>
      _storage.read(key: 'db_key_$organizationId');

  Future<void> saveDbKey(String organizationId, String hexKey) =>
      _storage.write(key: 'db_key_$organizationId', value: hexKey);

  /// "Entrar com digital" ligado nas Configurações. Quando ligado, o login
  /// guarda e-mail + senha (cifrados no Keychain/Keystore) para relogar por
  /// biometria depois que a sessão do servidor expira. Fora de `clearSession`
  /// de propósito — só `forgetBiometricLogin` (logout explícito) apaga.
  Future<bool> readBiometricLoginEnabled() async =>
      (await _storage.read(key: _kBiometricLoginEnabled)) == 'true';

  Future<void> setBiometricLoginEnabled(bool enabled) => _storage.write(
    key: _kBiometricLoginEnabled,
    value: enabled ? 'true' : 'false',
  );

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await Future.wait([
      _storage.write(key: _kSavedEmail, value: email),
      _storage.write(key: _kSavedPassword, value: password),
    ]);
  }

  Future<({String email, String password})?> readCredentials() async {
    final email = await _storage.read(key: _kSavedEmail);
    final password = await _storage.read(key: _kSavedPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  /// E-mail do último usuário que logou com sucesso neste aparelho. Sobrevive
  /// a `clearSession`, a `forgetBiometricLogin` e ao "Sair" — a tela de login
  /// sempre volta pré-preenchida com ele. Só é trocado pelo próximo login.
  Future<String?> readLastEmail() => _storage.read(key: _kLastEmail);

  Future<void> saveLastEmail(String email) =>
      _storage.write(key: _kLastEmail, value: email);

  /// Desliga o "entrar com digital" e esquece as credenciais salvas.
  Future<void> forgetBiometricLogin() async {
    await Future.wait([
      _storage.delete(key: _kBiometricLoginEnabled),
      _storage.delete(key: _kSavedEmail),
      _storage.delete(key: _kSavedPassword),
    ]);
  }

  /// UUID gerado uma vez por instalação (GUIA-FLUTTER.md §3.1) e persistido
  /// para sempre — nunca regenerado a cada login. Se o armazenamento for
  /// limpo (reinstalação, "limpar dados" do navegador), um novo id é
  /// gerado; o backend trata isso como um dispositivo novo, o que é correto.
  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = const Uuid().v4();
    await _storage.write(key: _kDeviceId, value: generated);
    return generated;
  }
}
