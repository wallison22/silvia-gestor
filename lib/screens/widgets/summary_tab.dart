import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/parsing.dart';
import '../../models/crochet_piece_record.dart';
import '../../models/piece_record.dart';
import '../../services/summary_service.dart';

const Color _kGreen = Color(0xFF059669);
const Color _kRed = Color(0xFFB91C1C);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextMid = Color(0xFF64748B);

const List<String> _kMonths = <String>[
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

class SummaryTab extends StatefulWidget {
  const SummaryTab({
    required this.pieces,
    required this.crochetPieces,
    required this.currency,
    super.key,
  });

  final List<PieceRecord> pieces;
  final List<CrochetPieceRecord> crochetPieces;
  final NumberFormat currency;

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  DateTime _month = _thisMonth();

  static DateTime _thisMonth() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void _move(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final MonthSummary s = summarizeMonth(
      pieces: widget.pieces,
      crochetPieces: widget.crochetPieces,
      year: _month.year,
      month: _month.month,
    );
    final NumberFormat c = widget.currency;
    Color color(double v) => v < 0 ? _kRed : _kGreen;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Mês anterior',
              onPressed: () => _move(-1),
            ),
            Expanded(
              child: Text(
                '${_kMonths[_month.month - 1]} de ${_month.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Próximo mês',
              onPressed:
                  _month.isBefore(_thisMonth()) ? () => _move(1) : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (s.sales.isEmpty)
          const _Box(children: <Widget>[
            Text(
              'Nenhuma venda neste mês.\n'
              'Use a etiqueta na peça para marcar como vendida.',
              style: TextStyle(color: _kTextMid),
            ),
          ])
        else ...<Widget>[
          _Box(children: <Widget>[
            _Line('Peças vendidas', '${s.sales.length}'),
            _Line('Total vendido', c.format(s.revenue), bold: true),
            _Line('Custo das peças', c.format(s.cost)),
            _Line('Lucro', c.format(s.profit),
                bold: true, color: color(s.profit)),
            const Divider(height: 20),
            _Line('Seu trabalho (${formatFixed(s.laborHours, 1)}h)',
                c.format(s.laborCost)),
            const Text(
              'Seu trabalho já está dentro do custo. O lucro é o que sobra '
              'além dele.',
              style: TextStyle(fontSize: 12, color: _kTextMid),
            ),
          ]),
          const _Title('O que mais rendeu'),
          _Box(children: <Widget>[
            for (final ProductTotal p in s.products)
              _Line('${p.name} (${p.count})', c.format(p.profit),
                  color: color(p.profit)),
          ]),
          const _Title('Vendas do mês'),
          _Box(children: <Widget>[
            for (final Sale sale in s.sales)
              _Line(
                '${sale.date.day.toString().padLeft(2, '0')}/'
                '${sale.date.month.toString().padLeft(2, '0')}  '
                '${sale.name}${sale.isCrochet ? ' (crochê)' : ''}',
                c.format(sale.price),
              ),
          ]),
        ],
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: _kTextDark)),
      );
}

class _Box extends StatelessWidget {
  const _Box({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false, this.color});
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final FontWeight w = bold ? FontWeight.w700 : FontWeight.w500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
              child: Text(label,
                  style: TextStyle(fontWeight: w, color: _kTextDark))),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(fontWeight: w, color: color ?? _kTextDark)),
        ],
      ),
    );
  }
}
