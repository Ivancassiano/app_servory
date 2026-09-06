import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/rest.dart';
import '../../../core/providers.dart';

/// `LabelTemplate` do OpenAPI (ADR-0017): texto de complemento "congelado"
/// para a folha de etiquetas. Alternativa ao `company_id` no PDF (mutuamente
/// exclusivos). Sempre REST — trabalho de escritório, online.
class LabelTemplate {
  const LabelTemplate({
    required this.id,
    this.companyId,
    required this.name,
    required this.body,
    this.version,
  });

  final String id;
  final String? companyId;
  final String name;
  final String body;
  final int? version;

  factory LabelTemplate.fromApiJson(Map<String, dynamic> j) => LabelTemplate(
    id: j['id'] as String,
    companyId: j['company_id'] as String?,
    name: (j['name'] as String?) ?? '',
    body: (j['body'] as String?) ?? '',
    version: j['version'] as int?,
  );
}

class LabelTemplateRepository {
  LabelTemplateRepository(this._dio);
  final Dio _dio;

  final _ctrl = StreamController<List<LabelTemplate>>.broadcast();
  List<LabelTemplate>? _cache;

  void dispose() => _ctrl.close();

  Stream<List<LabelTemplate>> watchList() {
    scheduleMicrotask(() {
      if (_cache != null) _ctrl.add(_cache!);
      unawaited(refresh());
    });
    return _ctrl.stream;
  }

  Future<void> refresh() async {
    try {
      final r = await restCall(() => _dio.get('/v1/label-templates'));
      final raw =
          (r.data as Map<String, dynamic>)['label_templates'] as List? ??
          const [];
      _cache = raw
          .map((e) => LabelTemplate.fromApiJson(e as Map<String, dynamic>))
          .toList();
      if (!_ctrl.isClosed) _ctrl.add(_cache!);
    } on ApiException catch (e) {
      if (!_ctrl.isClosed) _ctrl.addError(e);
    }
  }

  Future<LabelTemplate> create({
    String? companyId,
    required String name,
    required String body,
  }) async {
    final r = await restCall(
      () => _dio.post(
        '/v1/label-templates',
        data: {'company_id': ?companyId, 'name': name, 'body': body},
      ),
    );
    final t = LabelTemplate.fromApiJson(r.data as Map<String, dynamic>);
    await refresh();
    return t;
  }

  Future<void> update({
    required String id,
    required int? version,
    String? companyId,
    required String name,
    required String body,
  }) async {
    await restCall(
      () => _dio.patch(
        '/v1/label-templates/$id',
        data: {
          'company_id': ?companyId,
          'name': name,
          'body': body,
          'version': ?version,
        },
      ),
    );
    await refresh();
  }

  Future<void> delete(String id) async {
    await restCall(() => _dio.delete('/v1/label-templates/$id'));
    await refresh();
  }
}

final labelTemplateRepositoryProvider = Provider<LabelTemplateRepository>((ref) {
  final repo = LabelTemplateRepository(ref.watch(apiClientProvider).businessDio);
  ref.onDispose(repo.dispose);
  return repo;
});

final labelTemplateListProvider = StreamProvider<List<LabelTemplate>>(
  (ref) => ref.watch(labelTemplateRepositoryProvider).watchList(),
);
