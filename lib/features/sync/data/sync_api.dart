import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';

/// Uma operação da outbox local, no shape aceito por `POST /v1/sync/push`
/// (GUIA-FLUTTER.md §8.2).
class SyncOperationRequest {
  const SyncOperationRequest({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    this.baseVersion,
    required this.payload,
  });

  final String operationId;
  final String entityType;
  final String entityId;
  final String operationType;
  final int? baseVersion;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
    'operation_id': operationId,
    'entity_type': entityType,
    'entity_id': entityId,
    'operation_type': operationType,
    if (baseVersion != null) 'base_version': baseVersion,
    'payload': payload,
  };
}

/// `status` é `accepted` | `rejected` | `conflict` (GUIA-FLUTTER.md §8.2).
class SyncOperationResult {
  const SyncOperationResult({
    required this.operationId,
    required this.status,
    this.version,
    this.errorCode,
  });

  factory SyncOperationResult.fromJson(Map<String, dynamic> json) {
    return SyncOperationResult(
      operationId: json['operation_id'] as String,
      status: json['status'] as String,
      version: json['version'] as int?,
      errorCode: json['error_code'] as String?,
    );
  }

  final String operationId;
  final String status;
  final int? version;
  final String? errorCode;

  bool get accepted => status == 'accepted';
  bool get conflict => status == 'conflict';
}

class SyncEntityChange {
  const SyncEntityChange({
    required this.entityType,
    required this.entityId,
    required this.deleted,
    this.data,
  });

  factory SyncEntityChange.fromJson(Map<String, dynamic> json) {
    return SyncEntityChange(
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      deleted: json['deleted'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  final String entityType;
  final String entityId;
  final bool deleted;
  final Map<String, dynamic>? data;
}

class SyncPullResult {
  const SyncPullResult({required this.entities, required this.nextCursor});

  factory SyncPullResult.fromJson(Map<String, dynamic> json) {
    return SyncPullResult(
      entities: (json['entities'] as List? ?? const [])
          .map((e) => SyncEntityChange.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: (json['next_cursor'] as num).toInt(),
    );
  }

  final List<SyncEntityChange> entities;
  final int nextCursor;
}

class SyncBootstrapPage {
  const SyncBootstrapPage({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.cursor,
  });

  factory SyncBootstrapPage.fromJson(Map<String, dynamic> json) {
    return SyncBootstrapPage(
      items: (json['items'] as List? ?? const []).cast<Map<String, dynamic>>(),
      total: json['total'] as int,
      page: json['page'] as int,
      size: json['size'] as int,
      cursor: (json['cursor'] as num).toInt(),
    );
  }

  final List<Map<String, dynamic>> items;
  final int total;
  final int page;
  final int size;
  final int cursor;

  bool get hasMore => page * size < total;
}

/// Chamadas de `/v1/sync/*` (GUIA-FLUTTER.md §8.2), servidas pelo
/// `servicelog-api`.
class SyncApi {
  SyncApi(this._dio);

  final Dio _dio;

  Future<List<SyncOperationResult>> push(
    List<SyncOperationRequest> operations,
  ) async {
    try {
      final response = await _dio.post(
        '/v1/sync/push',
        data: {'operations': operations.map((o) => o.toJson()).toList()},
      );
      final results = (response.data['results'] as List? ?? const [])
          .map((r) => SyncOperationResult.fromJson(r as Map<String, dynamic>))
          .toList();
      return results;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SyncPullResult> pull({required int cursor, int limit = 200}) async {
    try {
      final response = await _dio.get(
        '/v1/sync/pull',
        queryParameters: {'cursor': cursor, 'limit': limit},
      );
      return SyncPullResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SyncBootstrapPage> bootstrap({
    required String entityType,
    required int page,
    int size = 100,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/sync/bootstrap',
        queryParameters: {
          'entity_type': entityType,
          'page': page,
          'size': size,
        },
      );
      return SyncBootstrapPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
