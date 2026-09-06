import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/remote_collection.dart';
import '../../../core/network/api_parse.dart';
import '../../../core/providers.dart';

/// `ClientContact` / `LocationContact` do OpenAPI — shape idêntico, só muda
/// o recurso-pai. **REST-only** (não entra no sync): a lista completa de
/// contatos é trabalho de cadastro, online. O "contato rápido"
/// (`contact_person`) continua no próprio cliente/local.
enum ContactScope {
  client('/v1/clients'),
  location('/v1/locations');

  const ContactScope(this.basePath);
  final String basePath;
}

/// Chave do `family` — `(escopo, id do pai)`. Records têm igualdade
/// estrutural, então o `StreamProvider.family` desduplica sozinho.
typedef ContactKey = (ContactScope scope, String parentId);

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
    required this.isPrimary,
    required this.isWhatsapp,
    required this.notes,
    this.version,
  });

  final String id;
  final String name;
  final String role;
  final String phone;
  final String email;
  final bool isPrimary;
  final bool isWhatsapp;
  final String notes;
  final int? version;

  factory Contact.fromApiJson(Map<String, dynamic> j) => Contact(
    id: j['id'] as String,
    name: stringOr(j['name']),
    role: stringOr(j['role']),
    phone: stringOr(j['phone']),
    email: stringOr(j['email']),
    isPrimary: j['is_primary'] as bool? ?? false,
    isWhatsapp: j['is_whatsapp'] as bool? ?? false,
    notes: stringOr(j['notes']),
    version: j['version'] as int?,
  );
}

Map<String, dynamic> _body({
  required String name,
  required String role,
  required String phone,
  required String email,
  required bool isPrimary,
  required bool isWhatsapp,
  required String notes,
}) => {
  'name': name,
  'role': role,
  'phone': phone,
  'email': email,
  'is_primary': isPrimary,
  'is_whatsapp': isWhatsapp,
  'notes': notes,
};

class ContactRepository {
  ContactRepository(this._ref);
  final Ref _ref;

  final _collections = <ContactKey, RemoteCollection<Contact>>{};

  RemoteCollection<Contact> _for(ContactKey key) =>
      _collections.putIfAbsent(key, () {
        final (scope, parentId) = key;
        return RemoteCollection<Contact>(
          dio: _ref.read(apiClientProvider).businessDio,
          listPath: '${scope.basePath}/$parentId/contacts',
          listKey: 'contacts',
          fromJson: Contact.fromApiJson,
          idOf: (c) => c.id,
        );
      });

  void dispose() {
    for (final c in _collections.values) {
      c.dispose();
    }
  }

  Stream<List<Contact>> watch(ContactKey key) => _for(key).watchList();

  Future<void> refresh(ContactKey key) => _for(key).refresh();

  Future<void> add(
    ContactKey key, {
    required String name,
    String role = '',
    String phone = '',
    String email = '',
    bool isPrimary = false,
    bool isWhatsapp = false,
    String notes = '',
  }) => _for(key).create(
    _body(
      name: name,
      role: role,
      phone: phone,
      email: email,
      isPrimary: isPrimary,
      isWhatsapp: isWhatsapp,
      notes: notes,
    ),
  );

  Future<void> update(
    ContactKey key,
    String contactId, {
    required int? version,
    required String name,
    required String role,
    required String phone,
    required String email,
    required bool isPrimary,
    required bool isWhatsapp,
    required String notes,
  }) => _for(key).update(contactId, {
    ..._body(
      name: name,
      role: role,
      phone: phone,
      email: email,
      isPrimary: isPrimary,
      isWhatsapp: isWhatsapp,
      notes: notes,
    ),
    'version': ?version,
  });

  Future<void> delete(ContactKey key, String contactId) =>
      _for(key).remove(contactId);
}

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  final repo = ContactRepository(ref);
  ref.onDispose(repo.dispose);
  return repo;
});

final contactsProvider = StreamProvider.family<List<Contact>, ContactKey>(
  (ref, key) => ref.watch(contactRepositoryProvider).watch(key),
);
