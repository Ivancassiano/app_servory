import 'dart:math';

import '../storage/secure_store.dart';

/// Gera/lê a chave de criptografia (256 bits, hex) do banco local de uma
/// organização, guardada no Keychain/Keystore via [SecureStore] (spec
/// §18.1). Chave crua (não derivada de senha) — usada com
/// `PRAGMA key = "x'<hex>'"` (sintaxe de blob literal do SQLCipher/
/// SQLite3 Multiple Ciphers para pular a derivação PBKDF2, já que a chave
/// já tem entropia total).
class DbKeyStore {
  DbKeyStore(this._store);

  final SecureStore _store;

  Future<String> getOrCreateHexKey(String organizationId) async {
    final existing = await _store.readDbKey(organizationId);
    if (existing != null && existing.length == 64) return existing;

    final generated = _generate256BitHexKey();
    await _store.saveDbKey(organizationId, generated);
    return generated;
  }

  String _generate256BitHexKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
