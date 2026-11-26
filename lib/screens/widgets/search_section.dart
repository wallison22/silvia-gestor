import 'package:flutter/material.dart';

enum SaleFilter {
  all('Todas'),
  available('À venda'),
  sold('Vendidas');

  const SaleFilter(this.label);
  final String label;
}

String _normalize(String s) {
  const String from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const String to = 'aaaaaeeeeiiiiooooouuuuc';
  final StringBuffer out = StringBuffer();
  for (final String c in s.toLowerCase().split('')) {
    final int i = from.indexOf(c);
    out.write(i < 0 ? c : to[i]);
  }
  return out.toString();
}

/// Busca por todas as palavras, sem diferenciar acentos e maiúsculas.
bool matchesSearch(String query, String text) {
  final String target = _normalize(text);
  return _normalize(query)
      .split(RegExp(r'\s+'))
      .every((String word) => target.contains(word));
}

/// Campo de busca (e filtro de vendas opcional) acima de uma lista.
class SearchSection<T> extends StatefulWidget {
  const SearchSection({
    required this.items,
    required this.textOf,
    required this.itemBuilder,
    this.isSold,
    super.key,
  });

  final List<T> items;
  final String Function(T item) textOf;
  final Widget Function(T item) itemBuilder;

  /// Se informado, mostra o filtro Todas / À venda / Vendidas.
  final bool Function(T item)? isSold;

  @override
  State<SearchSection<T>> createState() => _SearchSectionState<T>();
}

class _SearchSectionState<T> extends State<SearchSection<T>> {
  final TextEditingController _ctrl = TextEditingController();
  SaleFilter _filter = SaleFilter.all;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool Function(T)? isSold = widget.isSold;
    final List<T> visible = widget.items.where((T item) {
      if (isSold != null) {
        if (_filter == SaleFilter.available && isSold(item)) return false;
        if (_filter == SaleFilter.sold && !isSold(item)) return false;
      }
      return matchesSearch(_ctrl.text, widget.textOf(item));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: _ctrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar',
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _ctrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Limpar busca',
                    onPressed: () => setState(_ctrl.clear),
                  ),
          ),
        ),
        if (isSold != null) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final SaleFilter f in SaleFilter.values)
                ChoiceChip(
                  label: Text(f.label),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nada encontrado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        for (final T item in visible) widget.itemBuilder(item),
      ],
    );
  }
}
