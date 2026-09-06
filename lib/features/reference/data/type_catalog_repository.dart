import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';

/// Catálogos auxiliares com o mesmo shape (`{id, name, description, version}`)
/// e CRUD idêntico, só mudando o path: tipos de equipamento e tipos de ordem
/// de serviço. **REST-only** — cadastro é trabalho de escritório, online.
enum TypeCatalog {
  equipmentType('/v1/equipment-types', 'equipment_types', 'Tipo de equipamento'),
  serviceOrderType(
    '/v1/service-order-types',
    'service_order_types',
    'Tipo de ordem de serviço',
  );

  const TypeCatalog(this.path, this.listKey, this.singular);
  final String path;
  final String listKey;
  final String singular;
}

class TypeCatalogItem {
  const TypeCatalogItem({
    required this.id,
    required this.name,
    required this.description,
    this.version,
  });

  final String id;
  final String name;
  final String description;
  final int? version;

  factory TypeCatalogItem.fromApiJson(Map<String, dynamic> j) => TypeCatalogItem(
    id: j['id'] as String,
    name: (j['name'] as String?) ?? '',
    description: (j['description'] as String?) ?? '',
    version: j['version'] as int?,
  );
}

class TypeCatalogRepository {
  TypeCatalogRepository(this._dio);
  final Dio _dio;

  final _controllers = <TypeCatalog, StreamController<List<TypeCatalogItem>>>{};
  final _cache = <TypeCatalog, List<TypeCatalogItem>>{};

  StreamController<List<TypeCatalogItem>> _ctrl(TypeCatalog k) =>
      _controllers.putIfAbsent(
        k,
        () => StreamController<List<TypeCatalogItem>>.broadcast(),
      );

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
  }

  Stream<List<TypeCatalogItem>> watchList(TypeCatalog kind) {
    scheduleMicrotask(() {
      if (_cache.containsKey(kind)) _ctrl(kind).add(_cache[kind]!);
      unawaited(refresh(kind));
    });
    return _ctrl(kind).stream;
  }

  Future<void> refresh(TypeCatalog kind) async {
    try {
      final r = await restCall(() => _dio.get(kind.path));
      final raw =
          (r.data as Map<String, dynamic>)[kind.listKey] as List? ?? const [];
      final items = raw
          .map((e) => TypeCatalogItem.fromApiJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _cache[kind] = items;
      if (!_ctrl(kind).isClosed) _ctrl(kind).add(items);
    } on ApiException catch (e) {
      if (!_ctrl(kind).isClosed) _ctrl(kind).addError(e);
    }
  }

  Future<void> create(
    TypeCatalog kind, {
    required String name,
    String description = '',
  }) async {
    await restCall(
      () => _dio.post(
        kind.path,
        data: {'name': name, 'description': description},
      ),
    );
    await refresh(kind);
  }

  Future<void> update(
    TypeCatalog kind,
    String id, {
    required int? version,
    required String name,
    required String description,
  }) async {
    await restCall(
      () => _dio.patch(
        '${kind.path}/$id',
        data: {
          'name': name,
          'description': description,
          'version': ?version,
        },
      ),
    );
    await refresh(kind);
  }

  Future<void> delete(TypeCatalog kind, String id) async {
    await restCall(() => _dio.delete('${kind.path}/$id'));
    await refresh(kind);
  }
}

final typeCatalogRepositoryProvider = Provider<TypeCatalogRepository>((ref) {
  final repo = TypeCatalogRepository(ref.watch(apiClientProvider).businessDio);
  ref.onDispose(repo.dispose);
  return repo;
});

final typeCatalogListProvider =
    StreamProvider.family<List<TypeCatalogItem>, TypeCatalog>(
      (ref, kind) => ref.watch(typeCatalogRepositoryProvider).watchList(kind),
    );
