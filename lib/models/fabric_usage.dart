/// Representa o uso de um tecido especifico dentro de uma peca.
///
/// Calculo correto de custo por metro linear:
///   - area_usada = largura_usada * comprimento_usado
///   - metros_lineares_consumidos = area_usada / largura_do_tecido
///   - custo = metros_lineares_consumidos * preco_por_metro
class FabricUsage {
  FabricUsage({
    required this.fabricId,
    required this.fabricName,
    required this.fabricWidthMeters,
    required this.fabricPricePerMeter,
    required this.usedWidthMeters,
    required this.usedLengthMeters,
  });

  final String fabricId;
  final String fabricName;

  /// Largura total do rolo de tecido cadastrado no estoque.
  final double fabricWidthMeters;

  /// Preco por metro linear do tecido (como comprado na loja).
  final double fabricPricePerMeter;

  /// Largura efetivamente cortada para esta peca.
  final double usedWidthMeters;

  /// Comprimento efetivamente cortado para esta peca.
  final double usedLengthMeters;

  /// Area do retangulo cortado em m2.
  double get usedAreaSquareMeters => usedWidthMeters * usedLengthMeters;

  /// Metros lineares consumidos do rolo: area / largura_do_tecido.
  double get equivalentLengthUsedMeters =>
      fabricWidthMeters > 0 ? usedAreaSquareMeters / fabricWidthMeters : 0;

  /// Custo em reais: metros_lineares * preco_por_metro.
  double get fabricCost => equivalentLengthUsedMeters * fabricPricePerMeter;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fabricId': fabricId,
      'fabricName': fabricName,
      'fabricWidthMeters': fabricWidthMeters,
      'fabricPricePerMeter': fabricPricePerMeter,
      'usedWidthMeters': usedWidthMeters,
      'usedLengthMeters': usedLengthMeters,
    };
  }

  factory FabricUsage.fromJson(Map<String, dynamic> json) {
    return FabricUsage(
      fabricId: json['fabricId'] as String,
      fabricName: json['fabricName'] as String,
      fabricWidthMeters: (json['fabricWidthMeters'] as num).toDouble(),
      fabricPricePerMeter: (json['fabricPricePerMeter'] as num).toDouble(),
      usedWidthMeters: (json['usedWidthMeters'] as num).toDouble(),
      usedLengthMeters: (json['usedLengthMeters'] as num).toDouble(),
    );
  }
}
