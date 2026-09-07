import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/paged_source.dart';

/// Lista com campo de busca + pull-to-refresh, reaproveitada pelas telas de
/// listagem (clientes, locais, equipamentos, ordens…). A filtragem é **local**
/// sobre a lista já carregada.
///
/// No web, [paging] liga a paginação real: rolar até perto do fim busca a
/// próxima página; começar a digitar uma busca carrega todas as páginas que
/// faltam (a busca é client-side e daria resultado parcial sobre uma lista
/// incompleta). Nos apps [paging] é nulo — a lista inteira já vem do drift.
class SearchableListView<T> extends StatefulWidget {
  const SearchableListView({
    super.key,
    required this.async,
    required this.onRefresh,
    required this.searchText,
    required this.itemBuilder,
    required this.hintText,
    required this.emptyMessage,
    this.errorMessage = 'Não foi possível carregar.',
    this.filterBar,
    this.extraFilter,
    this.paging,
  });

  /// Estado da lista (loading / error / data).
  final AsyncValue<List<T>> async;

  /// Chamado no pull-to-refresh.
  final Future<void> Function() onRefresh;

  /// Texto pesquisável de um item (concatene os campos relevantes).
  final String Function(T item) searchText;

  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Placeholder do campo de busca.
  final String hintText;

  /// Mensagem quando a lista está vazia (nada cadastrado / sincronizado).
  final String emptyMessage;

  final String errorMessage;

  /// Área abaixo do campo de busca (ex.: chips de status). Fica fixa.
  final Widget? filterBar;

  /// Filtro adicional aplicado antes da busca textual (ex.: status escolhido).
  final bool Function(T item)? extraFilter;

  /// Fonte paginada (só web). Nulo nos apps.
  final PagedSource? paging;

  @override
  State<SearchableListView<T>> createState() => _SearchableListViewState<T>();
}

class _SearchableListViewState<T> extends State<SearchableListView<T>> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    widget.paging?.addListener(_onPagingChange);
  }

  @override
  void didUpdateWidget(SearchableListView<T> old) {
    super.didUpdateWidget(old);
    if (old.paging != widget.paging) {
      old.paging?.removeListener(_onPagingChange);
      widget.paging?.addListener(_onPagingChange);
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    widget.paging?.removeListener(_onPagingChange);
    _controller.dispose();
    super.dispose();
  }

  void _onPagingChange() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    final p = widget.paging;
    if (p == null || !p.hasMore || p.isLoadingMore) return;
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      p.loadMore();
    }
  }

  void _setQuery(String v) {
    setState(() => _query = v);
    // Busca client-side precisa do conjunto completo para não dar resultado
    // parcial — puxa o que falta assim que o usuário começa a digitar.
    if (v.trim().isNotEmpty) widget.paging?.loadAll();
  }

  /// minúsculas + sem acento, pra busca tolerante ("sao" acha "São").
  static String _fold(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      b.write(i == -1 ? ch : to[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return widget.async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '${widget.errorMessage}\n$e',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (items) {
        final terms = _fold(_query).split(' ').where((t) => t.isNotEmpty);
        final searching = terms.isNotEmpty;
        final visible = [
          for (final item in items)
            if (widget.extraFilter?.call(item) ?? true)
              if (terms.every(
                (t) => _fold(widget.searchText(item)).contains(t),
              ))
                item,
        ];

        final paging = widget.paging;
        // Rodapé "carregar mais" só quando não há busca (na busca usamos
        // loadAll) e ainda faltam páginas.
        final showFooter =
            !searching &&
            paging != null &&
            (paging.hasMore || paging.isLoadingMore);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _controller,
                onChanged: _setQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.hintText,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (searching && paging != null && paging.isLoadingMore)
              const LinearProgressIndicator(minHeight: 2),
            if (widget.filterBar != null) ...[
              widget.filterBar!,
              const SizedBox(height: 4),
            ],
            Expanded(
              child: RefreshIndicator(
                onRefresh: widget.onRefresh,
                child: visible.isEmpty
                    ? ListView(
                        controller: _scroll,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                items.isEmpty
                                    ? widget.emptyMessage
                                    : 'Nenhum resultado.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        controller: _scroll,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: visible.length + (showFooter ? 1 : 0),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          if (i >= visible.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          return widget.itemBuilder(context, visible[i]);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
