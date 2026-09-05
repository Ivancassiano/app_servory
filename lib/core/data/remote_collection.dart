// Campos privados inicializados por parâmetro nomeado — não há forma de
// initializing formal para isso (nomeados não aceitam `this._x`).
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:dio/dio.dart';

import '../network/rest.dart';

/// Espelho em memória de uma coleção REST, para o alvo web (que não tem
/// banco local). Mantém um cache + um `Stream` broadcast que reemite a cada
/// escrita ou `refresh()`, para os `StreamProvider` de lista/detalhe
/// continuarem funcionando iguais nos dois alvos.
///
/// Erros de carga entram no stream via `addError` (o `StreamProvider` os
/// expõe como `AsyncError`) sem derrubar a assinatura — um `refresh()`
/// posterior (pull-to-refresh) recupera.
class RemoteCollection<T> {
  RemoteCollection({
    required Dio dio,
    required String listPath,
    required String listKey,
    required T Function(Map<String, dynamic> json) fromJson,
    required String Function(T item) idOf,
    String? itemPath,
    Map<String, dynamic> listQuery = const {'size': 500},
  }) : _dio = dio,
       _listPath = listPath,
       _listKey = listKey,
       _fromJson = fromJson,
       _idOf = idOf,
       _itemPath = itemPath ?? listPath,
       _listQuery = listQuery;

  final Dio _dio;
  final String _listPath;
  final String _itemPath;
  final String _listKey;
  final Map<String, dynamic> _listQuery;
  final T Function(Map<String, dynamic>) _fromJson;
  final String Function(T) _idOf;

  final _ctrl = StreamController<List<T>>.broadcast();
  List<T>? _cache;
  Future<void>? _inFlight;

  void dispose() => _ctrl.close();

  Stream<List<T>> watchList() {
    if (_cache == null && _inFlight == null) _inFlight = refresh();
    return _withCurrent();
  }

  Stream<List<T>> _withCurrent() async* {
    if (_cache != null) yield _cache!;
    yield* _ctrl.stream;
  }

  Stream<T?> watchById(String id) async* {
    final cached = _find(id);
    if (cached != null) {
      yield cached;
    } else {
      final r = await restCall(() => _dio.get('$_itemPath/$id'));
      yield _fromJson(r.data as Map<String, dynamic>);
    }
    yield* _ctrl.stream.map((_) => _find(id));
  }

  T? _find(String id) {
    for (final item in _cache ?? <T>[]) {
      if (_idOf(item) == id) return item;
    }
    return null;
  }

  Future<void> refresh() async {
    try {
      final r = await restCall(
        () => _dio.get(_listPath, queryParameters: _listQuery),
      );
      final raw = (r.data as Map<String, dynamic>)[_listKey] as List? ?? const [];
      _cache = raw
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      _ctrl.add(_cache!);
    } catch (e) {
      if (!_ctrl.isClosed) _ctrl.addError(e);
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  /// POST no endpoint da coleção. `body` é o corpo REST já pronto.
  Future<T> create(Map<String, dynamic> body, {String? path}) async {
    final r = await restCall(
      () => _dio.post(path ?? _listPath, data: body),
    );
    final item = _fromJson(r.data as Map<String, dynamic>);
    _upsertLocal(item);
    return item;
  }

  /// PATCH em `<itemPath>/<id>`.
  Future<T> update(String id, Map<String, dynamic> body) async {
    final r = await restCall(() => _dio.patch('$_itemPath/$id', data: body));
    final item = _fromJson(r.data as Map<String, dynamic>);
    _upsertLocal(item);
    return item;
  }

  /// POST em `<itemPath>/<id>/<action>` (ex.: `start`, `assign`).
  Future<T> action(String id, String action, Map<String, dynamic> body) async {
    final r = await restCall(
      () => _dio.post('$_itemPath/$id/$action', data: body),
    );
    final item = _fromJson(r.data as Map<String, dynamic>);
    _upsertLocal(item);
    return item;
  }

  /// DELETE em `<itemPath>/<id>` (204, sem corpo).
  Future<void> remove(String id) async {
    await restCall(() => _dio.delete('$_itemPath/$id'));
    _cache = [
      for (final item in _cache ?? <T>[])
        if (_idOf(item) != id) item,
    ];
    _ctrl.add(_cache!);
  }

  void _upsertLocal(T item) {
    final id = _idOf(item);
    final next = <T>[];
    var replaced = false;
    for (final existing in _cache ?? <T>[]) {
      if (_idOf(existing) == id) {
        next.add(item);
        replaced = true;
      } else {
        next.add(existing);
      }
    }
    if (!replaced) next.add(item);
    _cache = next;
    _ctrl.add(_cache!);
  }
}
