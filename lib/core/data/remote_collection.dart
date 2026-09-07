// Campos privados inicializados por parâmetro nomeado — não há forma de
// initializing formal para isso (nomeados não aceitam `this._x`).
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/rest.dart';
import 'paged_source.dart';

/// Espelho em memória de uma coleção REST, para o alvo web (que não tem
/// banco local). Mantém um cache + um `Stream` broadcast que reemite a cada
/// escrita ou `refresh()`, para os `StreamProvider` de lista/detalhe
/// continuarem funcionando iguais nos dois alvos.
///
/// Erros de carga entram no stream via `addError` (o `StreamProvider` os
/// expõe como `AsyncError`) sem derrubar a assinatura — um `refresh()`
/// posterior (pull-to-refresh) recupera.
///
/// Com [pageSize] definido entra em **modo paginado** (`page`/`size` +
/// `total` da resposta): `refresh()` busca a 1ª página e `loadMore()`/
/// `loadAll()` anexam as seguintes. Sem [pageSize] o comportamento é o
/// antigo: uma única busca (`_listQuery`, default `size: 500`) — usado pelos
/// sub-recursos pequenos (contatos, peças, recomendações…).
class RemoteCollection<T> extends ChangeNotifier implements PagedSource {
  RemoteCollection({
    required Dio dio,
    required String listPath,
    required String listKey,
    required T Function(Map<String, dynamic> json) fromJson,
    required String Function(T item) idOf,
    String? itemPath,
    Map<String, dynamic> listQuery = const {'size': 500},
    int? pageSize,
  }) : _dio = dio,
       _listPath = listPath,
       _listKey = listKey,
       _fromJson = fromJson,
       _idOf = idOf,
       _itemPath = itemPath ?? listPath,
       _listQuery = listQuery,
       _pageSize = pageSize;

  final Dio _dio;
  final String _listPath;
  final String _itemPath;
  final String _listKey;
  final Map<String, dynamic> _listQuery;
  final int? _pageSize;
  final T Function(Map<String, dynamic>) _fromJson;
  final String Function(T) _idOf;

  final _ctrl = StreamController<List<T>>.broadcast();
  List<T>? _cache;
  Future<void>? _inFlight;

  int _page = 1;
  int? _total;
  bool _loadingMore = false;

  @override
  void dispose() {
    _ctrl.close();
    super.dispose();
  }

  /// `notifyListeners` só enquanto vivo — `refresh`/`loadMore` em voo podem
  /// terminar depois do `dispose` do provider.
  void _safeNotify() {
    if (!_ctrl.isClosed) notifyListeners();
  }

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
      final query = _pageSize == null
          ? _listQuery
          : {..._listQuery, 'page': 1, 'size': _pageSize};
      final r = await restCall(
        () => _dio.get(_listPath, queryParameters: query),
      );
      final data = r.data as Map<String, dynamic>;
      final raw = data[_listKey] as List? ?? const [];
      _cache = [for (final e in raw) _fromJson(e as Map<String, dynamic>)];
      if (_pageSize != null) {
        _page = 1;
        _total = data['total'] as int?;
      }
      _ctrl.add(_cache!);
      _safeNotify();
    } catch (e) {
      if (!_ctrl.isClosed) _ctrl.addError(e);
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  // --- PagedSource -------------------------------------------------------

  @override
  bool get hasMore =>
      _pageSize != null &&
      _cache != null &&
      _total != null &&
      _cache!.length < _total!;

  @override
  bool get isLoadingMore => _loadingMore;

  @override
  Future<void> loadMore() async {
    if (_pageSize == null || _loadingMore || !hasMore) return;
    _loadingMore = true;
    _safeNotify();
    try {
      final r = await restCall(
        () => _dio.get(
          _listPath,
          queryParameters: {
            ..._listQuery,
            'page': _page + 1,
            'size': _pageSize,
          },
        ),
      );
      final data = r.data as Map<String, dynamic>;
      final raw = data[_listKey] as List? ?? const [];
      _page++;
      _total = data['total'] as int? ?? _total;
      _cache = [
        ...?_cache,
        for (final e in raw) _fromJson(e as Map<String, dynamic>),
      ];
      _ctrl.add(_cache!);
    } catch (e) {
      if (!_ctrl.isClosed) _ctrl.addError(e);
    } finally {
      _loadingMore = false;
      _safeNotify();
    }
  }

  @override
  Future<void> loadAll() async {
    while (hasMore && !_loadingMore) {
      final before = _cache?.length ?? 0;
      await loadMore();
      if ((_cache?.length ?? 0) <= before) break; // servidor não avançou
    }
  }

  /// POST no endpoint da coleção. `body` é o corpo REST já pronto.
  Future<T> create(Map<String, dynamic> body, {String? path}) async {
    final r = await restCall(() => _dio.post(path ?? _listPath, data: body));
    final item = _fromJson(r.data as Map<String, dynamic>);
    _upsertLocal(item);
    if (_pageSize != null && _total != null) _total = _total! + 1;
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
    if (_pageSize != null && _total != null && _total! > 0) {
      _total = _total! - 1;
    }
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
