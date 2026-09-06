import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/remote_collection.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_parse.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';

/// `Company` do OpenAPI — a(s) empresa(s) emissora(s) das ordens/laudos da
/// organização. **REST-only** (não entra no sync): cadastro de escritório.
/// `kind: 'individual'` = o próprio profissional (exige `person_user_id`).
class Company {
  const Company({
    required this.id,
    required this.kind,
    this.personUserId,
    required this.name,
    required this.legalName,
    required this.taxId,
    required this.taxRegime,
    required this.phone,
    required this.email,
    required this.address,
    required this.notes,
    this.logo,
    this.version,
  });

  final String id;
  final String kind; // legal | individual
  final String? personUserId;
  final String name;
  final String legalName;
  final String taxId;
  final String taxRegime;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final CompanyLogo? logo;
  final int? version;

  bool get hasLogo => logo != null;

  factory Company.fromApiJson(Map<String, dynamic> j) => Company(
    id: j['id'] as String,
    kind: stringOr(j['kind'], 'legal'),
    personUserId: j['person_user_id'] as String?,
    name: stringOr(j['name']),
    legalName: stringOr(j['legal_name']),
    taxId: stringOr(j['tax_id']),
    taxRegime: stringOr(j['tax_regime']),
    phone: stringOr(j['phone']),
    email: stringOr(j['email']),
    address: stringOr(j['address']),
    notes: stringOr(j['notes']),
    logo: j['logo'] is Map<String, dynamic>
        ? CompanyLogo.fromApiJson(j['logo'] as Map<String, dynamic>)
        : null,
    version: j['version'] as int?,
  );
}

class CompanyLogo {
  const CompanyLogo({
    required this.contentType,
    required this.sizeBytes,
    required this.sha256,
  });

  final String contentType;
  final int sizeBytes;
  final String sha256;

  factory CompanyLogo.fromApiJson(Map<String, dynamic> j) => CompanyLogo(
    contentType: stringOr(j['content_type']),
    sizeBytes: j['size_bytes'] as int? ?? 0,
    sha256: stringOr(j['sha256']),
  );
}

class CompanyMember {
  const CompanyMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.isPrimary,
    this.version,
  });

  final String userId;
  final String name;
  final String email;
  final bool isPrimary;
  final int? version;

  factory CompanyMember.fromApiJson(Map<String, dynamic> j) => CompanyMember(
    userId: stringOr(j['user_id']),
    name: stringOr(j['name']),
    email: stringOr(j['email']),
    isPrimary: j['is_primary'] as bool? ?? false,
    version: j['version'] as int?,
  );
}

Map<String, dynamic> _companyBody({
  required String kind,
  String? personUserId,
  required String name,
  required String legalName,
  required String taxId,
  required String taxRegime,
  required String phone,
  required String email,
  required String address,
  required String notes,
}) => {
  'kind': kind,
  'person_user_id': ?personUserId,
  'name': name,
  'legal_name': legalName,
  'tax_id': taxId,
  'tax_regime': taxRegime,
  'phone': phone,
  'email': email,
  'address': address,
  'notes': notes,
};

class CompanyRepository {
  CompanyRepository(this._dio);
  final Dio _dio;

  late final RemoteCollection<Company> _companies = RemoteCollection<Company>(
    dio: _dio,
    listPath: '/v1/companies',
    listKey: 'companies',
    fromJson: Company.fromApiJson,
    idOf: (c) => c.id,
  );

  final _members = <String, RemoteCollection<CompanyMember>>{};

  RemoteCollection<CompanyMember> _membersFor(String companyId) =>
      _members.putIfAbsent(
        companyId,
        () => RemoteCollection<CompanyMember>(
          dio: _dio,
          listPath: '/v1/companies/$companyId/members',
          listKey: 'members',
          fromJson: CompanyMember.fromApiJson,
          idOf: (m) => m.userId,
        ),
      );

  void dispose() {
    _companies.dispose();
    for (final m in _members.values) {
      m.dispose();
    }
  }

  // --- empresas -----------------------------------------------------------

  Stream<List<Company>> watchList() => _companies.watchList();

  Stream<Company?> watchById(String id) => _companies.watchById(id);

  Future<void> refresh() => _companies.refresh();

  Future<Company> create({
    required String kind,
    String? personUserId,
    required String name,
    String legalName = '',
    String taxId = '',
    String taxRegime = '',
    String phone = '',
    String email = '',
    String address = '',
    String notes = '',
  }) => _companies.create(
    _companyBody(
      kind: kind,
      personUserId: personUserId,
      name: name,
      legalName: legalName,
      taxId: taxId,
      taxRegime: taxRegime,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    ),
  );

  Future<void> update(
    String id, {
    required int? version,
    required String kind,
    String? personUserId,
    required String name,
    required String legalName,
    required String taxId,
    required String taxRegime,
    required String phone,
    required String email,
    required String address,
    required String notes,
  }) => _companies.update(id, {
    ..._companyBody(
      kind: kind,
      personUserId: personUserId,
      name: name,
      legalName: legalName,
      taxId: taxId,
      taxRegime: taxRegime,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    ),
    'version': ?version,
  });

  Future<void> delete(String id) => _companies.remove(id);

  // --- membros -----------------------------------------------------------

  Stream<List<CompanyMember>> watchMembers(String companyId) =>
      _membersFor(companyId).watchList();

  Future<void> refreshMembers(String companyId) =>
      _membersFor(companyId).refresh();

  Future<void> addMember(
    String companyId, {
    required String userId,
    bool isPrimary = false,
  }) => _membersFor(companyId).create({
    'user_id': userId,
    'is_primary': isPrimary,
  });

  Future<void> setMemberPrimary(
    String companyId,
    String userId, {
    required bool isPrimary,
  }) => _membersFor(companyId).update(userId, {'is_primary': isPrimary});

  Future<void> removeMember(String companyId, String userId) =>
      _membersFor(companyId).remove(userId);

  // --- logo ------------------------------------------------------------

  Future<void> setLogo(
    String companyId, {
    required Uint8List bytes,
    required String filename,
  }) async {
    await restCall(
      () => _dio.post(
        '/v1/companies/$companyId/logo',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: filename),
        }),
      ),
    );
    await _companies.refresh();
  }

  Future<void> deleteLogo(String companyId) async {
    await restCall(() => _dio.delete('/v1/companies/$companyId/logo'));
    await _companies.refresh();
  }

  /// URL assinada e temporária (spec §26.4) para exibir o logo.
  Future<String?> logoDownloadUrl(String companyId) async {
    try {
      final r = await restCall(
        () => _dio.get('/v1/companies/$companyId/logo/download'),
      );
      return (r.data as Map)['url'] as String?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final repo = CompanyRepository(ref.watch(apiClientProvider).businessDio);
  ref.onDispose(repo.dispose);
  return repo;
});

final companyListProvider = StreamProvider<List<Company>>(
  (ref) => ref.watch(companyRepositoryProvider).watchList(),
);

final companyByIdProvider = StreamProvider.family<Company?, String>(
  (ref, id) => ref.watch(companyRepositoryProvider).watchById(id),
);

final companyMembersProvider =
    StreamProvider.family<List<CompanyMember>, String>(
      (ref, companyId) =>
          ref.watch(companyRepositoryProvider).watchMembers(companyId),
    );
