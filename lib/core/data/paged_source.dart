import 'package:flutter/foundation.dart';

/// Fonte de lista paginada — só existe no alvo web. Nos apps a lista inteira
/// vem do drift local, então não há o que paginar.
///
/// [SearchableListView] usa isto para (a) carregar a próxima página ao rolar
/// perto do fim e (b) carregar tudo que falta quando há busca ativa — a busca
/// é client-side e daria resultado parcial sobre uma lista incompleta.
abstract class PagedSource implements Listenable {
  /// Ainda há itens no servidor além dos já carregados.
  bool get hasMore;

  /// Uma página está sendo buscada agora.
  bool get isLoadingMore;

  /// Busca e anexa a próxima página. No-op se [hasMore] for falso ou já
  /// houver uma carga em andamento.
  Future<void> loadMore();

  /// Carrega repetidamente até esgotar [hasMore].
  Future<void> loadAll();
}

/// Marcador para o repositório cuja lista principal é paginada (web).
/// A tela de lista lê o [PagedSource] por aqui via um provider dedicado.
abstract interface class PagedListRepository {
  PagedSource? get listPaging;
}

/// [PagedSource] de um repositório, ou `null` se ele não pagina (apps).
PagedSource? pagingOf(Object? repository) =>
    repository is PagedListRepository ? repository.listPaging : null;
