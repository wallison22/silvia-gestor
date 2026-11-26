import '../models/crochet_piece_record.dart';
import '../models/piece_record.dart';

class Sale {
  Sale({
    required this.name,
    required this.isCrochet,
    required this.date,
    required this.price,
    required this.cost,
    required this.laborCost,
    required this.laborHours,
  });

  final String name;
  final bool isCrochet;
  final DateTime date;
  final double price;
  final double cost;
  final double laborCost;
  final double laborHours;

  double get profit => price - cost;
}

/// Vendas de um mesmo tipo de peça (mesmo nome).
class ProductTotal {
  ProductTotal(this.name);

  final String name;
  int count = 0;
  double profit = 0;
}

class MonthSummary {
  MonthSummary(this.sales);

  /// Da mais recente para a mais antiga.
  final List<Sale> sales;

  double _sum(double Function(Sale s) f) =>
      sales.fold(0, (double t, Sale s) => t + f(s));

  double get revenue => _sum((Sale s) => s.price);
  double get cost => _sum((Sale s) => s.cost);
  double get profit => _sum((Sale s) => s.profit);
  double get laborCost => _sum((Sale s) => s.laborCost);
  double get laborHours => _sum((Sale s) => s.laborHours);

  /// Produtos que mais deram lucro primeiro.
  List<ProductTotal> get products {
    final Map<String, ProductTotal> map = <String, ProductTotal>{};
    for (final Sale s in sales) {
      final String name = s.name.trim();
      final ProductTotal p =
          map.putIfAbsent(name.toLowerCase(), () => ProductTotal(name));
      p.count++;
      p.profit += s.profit;
    }
    return map.values.toList()
      ..sort((ProductTotal a, ProductTotal b) => b.profit.compareTo(a.profit));
  }
}

MonthSummary summarizeMonth({
  required List<PieceRecord> pieces,
  required List<CrochetPieceRecord> crochetPieces,
  required int year,
  required int month,
}) {
  final List<Sale> sales = <Sale>[];
  void add(String name, bool crochet, double? price, String? soldAt,
      double cost, double labor, double hours) {
    final DateTime? date = soldAt == null ? null : DateTime.tryParse(soldAt);
    if (price == null || date == null) return;
    if (date.year != year || date.month != month) return;
    sales.add(Sale(
      name: name,
      isCrochet: crochet,
      date: date,
      price: price,
      cost: cost,
      laborCost: labor,
      laborHours: hours,
    ));
  }

  for (final PieceRecord p in pieces) {
    add(p.pieceName, false, p.soldPrice, p.soldAtIso, p.productionCost,
        p.laborCost, p.laborHours);
  }
  for (final CrochetPieceRecord p in crochetPieces) {
    add(p.pieceName, true, p.soldPrice, p.soldAtIso, p.productionCost,
        p.laborCost, p.laborHours);
  }
  sales.sort((Sale a, Sale b) => b.date.compareTo(a.date));
  return MonthSummary(sales);
}
