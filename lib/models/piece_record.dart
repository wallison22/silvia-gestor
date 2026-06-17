import 'fabric_usage.dart';

/// Registro imutavel de uma peca produzida.
///
/// Guarda um snapshot dos calculos no momento da criacao, assim os dados
/// nao mudam mesmo que o tecido seja editado depois.
class PieceRecord {
  PieceRecord({
    required this.id,
    required this.pieceName,
    required this.fabricUsages,
    required this.additionalMaterialsCost,
    required this.laborHours,
    required this.hourlyValue,
    required this.laborCost,
    required this.operationalCost,
    required this.productionCost,
    required this.suggestedPrice,
    required this.createdAtIso,
  });

  final String id;
  final String pieceName;

  /// Lista de tecidos consumidos nesta peca.
  final List<FabricUsage> fabricUsages;

  /// Custo de aviamentos e outros materiais (R$).
  final double additionalMaterialsCost;

  final double laborHours;

  // ── Precificacao (4 pilares) ──────────────────────────────────────
  final double hourlyValue;
  final double laborCost;
  final double operationalCost;
  final double productionCost;
  final double suggestedPrice;

  final String createdAtIso;

  // ── Calculados a partir da lista de tecidos ───────────────────────

  /// Soma dos custos de tecido de todos os usos.
  double get totalFabricCost =>
      fabricUsages.fold(0, (double s, FabricUsage u) => s + u.fabricCost);

  /// Custo total de materiais (tecidos + aviamentos).
  double get totalMaterialsCost => totalFabricCost + additionalMaterialsCost;

  /// Nomes dos tecidos usados, separados por virgula.
  String get fabricsDescription =>
      fabricUsages.map((FabricUsage u) => u.fabricName).toSet().join(', ');

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'pieceName': pieceName,
      'fabricUsages': fabricUsages.map((FabricUsage u) => u.toJson()).toList(),
      'additionalMaterialsCost': additionalMaterialsCost,
      'laborHours': laborHours,
      'hourlyValue': hourlyValue,
      'laborCost': laborCost,
      'operationalCost': operationalCost,
      'productionCost': productionCost,
      'suggestedPrice': suggestedPrice,
      'createdAtIso': createdAtIso,
    };
  }

  factory PieceRecord.fromJson(Map<String, dynamic> json) {
    // Compatibilidade com registros antigos (formato pre-refatoracao):
    // se existir 'fabricId' no JSON, converte para FabricUsage unico.
    List<FabricUsage> usages;
    if (json.containsKey('fabricUsages')) {
      usages = (json['fabricUsages'] as List<dynamic>)
          .map((dynamic e) => FabricUsage.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      usages = <FabricUsage>[
        FabricUsage(
          fabricId: json['fabricId'] as String,
          fabricName: json['fabricName'] as String,
          fabricWidthMeters: 1,
          fabricPricePerMeter: (json['fabricCost'] as num).toDouble() /
              (((json['usedWidthMeters'] as num).toDouble() *
                      (json['usedLengthMeters'] as num).toDouble()) /
                  1),
          usedWidthMeters: (json['usedWidthMeters'] as num).toDouble(),
          usedLengthMeters: (json['usedLengthMeters'] as num).toDouble(),
        ),
      ];
    }

    return PieceRecord(
      id: json['id'] as String,
      pieceName: json['pieceName'] as String,
      fabricUsages: usages,
      additionalMaterialsCost:
          (json['additionalMaterialsCost'] as num).toDouble(),
      laborHours: (json['laborHours'] as num).toDouble(),
      hourlyValue: (json['hourlyValue'] as num).toDouble(),
      laborCost: (json['laborCost'] as num).toDouble(),
      operationalCost: (json['operationalCost'] as num).toDouble(),
      productionCost: (json['productionCost'] as num).toDouble(),
      suggestedPrice: (json['suggestedPrice'] as num).toDouble(),
      createdAtIso: json['createdAtIso'] as String,
    );
  }
}
