import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';

/// Dados pessoais do ator — pessoa 1:1 com o usuário, global à conta
/// (schema `Person` do OpenAPI, `GET/PATCH /v1/me/person`). Campos vazios
/// quando ainda não cadastrada. Sem trava otimista: o backend faz merge
/// campo a campo.
class Person {
  const Person({
    required this.fullName,
    required this.taxId,
    required this.phone,
    required this.professionalRegistration,
    required this.notes,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    fullName: json['full_name'] as String? ?? '',
    taxId: json['tax_id'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    professionalRegistration:
        json['professional_registration'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
  );

  static const empty = Person(
    fullName: '',
    taxId: '',
    phone: '',
    professionalRegistration: '',
    notes: '',
  );

  final String fullName;
  final String taxId;
  final String phone;

  /// Registro profissional (CREA/CFT) — sai no laudo.
  final String professionalRegistration;
  final String notes;
}

class PersonApi {
  PersonApi(this._dio);

  final Dio _dio;

  Future<Person> getMyPerson() async {
    try {
      final response = await _dio.get('/v1/me/person');
      return Person.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Merge campo a campo — manda os cinco campos sempre, para que limpar
  /// um no formulário limpe no servidor.
  Future<Person> updateMyPerson({
    required String fullName,
    required String taxId,
    required String phone,
    required String professionalRegistration,
    required String notes,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/v1/me/person',
        data: {
          'full_name': fullName,
          'tax_id': taxId,
          'phone': phone,
          'professional_registration': professionalRegistration,
          'notes': notes,
        },
      );
      return Person.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
