import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';

/// Fotos e assinatura de ordem de serviço (GUIA-FLUTTER.md §7) — REST puro,
/// fora do protocolo de sync. Download nunca vem em binário direto: o
/// servidor sempre devolve uma URL assinada e temporária (§26.4), que
/// `Image.network` consome normalmente.
class AttachmentsApi {
  AttachmentsApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> addPhoto({
    required String serviceOrderId,
    required File file,
    String? kind,
    String? caption,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/service-orders/$serviceOrderId/photos',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path),
          'kind': ?kind,
          if (caption != null && caption.isNotEmpty) 'caption': caption,
        }),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> listPhotos(String serviceOrderId) async {
    try {
      final response = await _dio.get(
        '/v1/service-orders/$serviceOrderId/photos',
      );
      return ((response.data as Map)['photos'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deletePhoto({
    required String serviceOrderId,
    required String photoId,
  }) async {
    try {
      await _dio.delete('/v1/service-orders/$serviceOrderId/photos/$photoId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> photoDownloadUrl({
    required String serviceOrderId,
    required String photoId,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/service-orders/$serviceOrderId/photos/$photoId/download',
      );
      return (response.data as Map)['url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> putSignature({
    required String serviceOrderId,
    required File file,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/service-orders/$serviceOrderId/signature',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path),
        }),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `null` quando a ordem ainda não tem assinatura coletada (404) — não é
  /// tratado como erro, é o estado normal antes da 1ª coleta.
  Future<Map<String, dynamic>?> getSignature(String serviceOrderId) async {
    try {
      final response = await _dio.get(
        '/v1/service-orders/$serviceOrderId/signature',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final ex = ApiException.fromDio(e);
      if (ex.statusCode == 404) return null;
      throw ex;
    }
  }

  Future<void> deleteSignature(String serviceOrderId) async {
    try {
      await _dio.delete('/v1/service-orders/$serviceOrderId/signature');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> signatureDownloadUrl(String serviceOrderId) async {
    try {
      final response = await _dio.get(
        '/v1/service-orders/$serviceOrderId/signature/download',
      );
      return (response.data as Map)['url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
