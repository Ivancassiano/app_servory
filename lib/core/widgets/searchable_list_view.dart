import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lista com campo de busca + pull-to-refresh, reaproveitada pelas telas de
/// listagem (clientes, locais, equipamentos, ordens…). A filtragem é **local**
/// sobre a lista já carregada — as listas hoje puxam tudo (`size: 500`), então
/// isso cobre o uso real; busca no servidor + paginação fica pra depois.
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

  @override
  State<SearchableListView<T>> createState() => _SearchableListViewState<T>();
}

class _SearchableListViewState<T> extends State<SearchableListView<T>> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          child: Text('${widget.errorMessage}\n$e', textAlign: TextAlign.center),
        ),
      ),
      data: (items) {
        final terms = _fold(_query).split(' ').where((t) => t.isNotEmpty);
        final visible = [
          for (final item in items)
            if (widget.extraFilter?.call(item) ?? true)
              if (terms.every((t) => _fold(widget.searchText(item)).contains(t)))
                item,
        ];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _controller,
                onChanged: (v) => setState(() => _query = v),
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
            if (widget.filterBar != null) ...[
              widget.filterBar!,
              const SizedBox(height: 4),
            ],
            Expanded(
              child: RefreshIndicator(
                onRefresh: widget.onRefresh,
                child: visible.isEmpty
                    ? ListView(
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
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            widget.itemBuilder(context, visible[i]),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
