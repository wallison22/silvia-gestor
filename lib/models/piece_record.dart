import 'fabric_usage.dart';

/// Registro imutavel de uma peça produzida.
///
/// Guarda um snapshot dos calculos no momento da criacao, assim os dados
/// não mudam mesmo que o tecido seja editado depois.
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
    this.soldPrice,
    this.soldAtIso,
    this.photoName,
  });

  final String id;
  final String pieceName;

  /// Lista de tecidos consumidos nesta peça.
  final List<FabricUsage> fabricUsages;

  /// Custo de aviamentos e outros materiais (R$).
  final double additionalMaterialsCost;

  final double laborHours;

  // ── Precificação (4 pilares) ──────────────────────────────────────
  final double hourlyValue;
  final double laborCost;
  final double operationalCost;
  final double productionCost;
  final double suggestedPrice;

  final String createdAtIso;

  /// Valor pelo qual a peça foi vendida; null se ainda não foi.
  final double? soldPrice;
  final String? soldAtIso;

  /// Arquivo da foto; null se não tiver.
  final String? photoName;

  bool get isSold => soldPrice != null;

  /// Lucro real da venda; null se ainda não foi vendida.
  double? get saleProfit =>
      soldPrice == null ? null : soldPrice! - productionCost;

  /// Copia mudando so nome e foto, sem mexer em custos e preço.
  PieceRecord withDetails(String name, String? photo) => PieceRecord(
        id: id,
        pieceName: name,
        photoName: photo,
        fabricUsages: fabricUsages,
        additionalMaterialsCost: additionalMaterialsCost,
        laborHours: laborHours,
        hourlyValue: hourlyValue,
        laborCost: laborCost,
        operationalCost: operationalCost,
        productionCost: productionCost,
        suggestedPrice: suggestedPrice,
        createdAtIso: createdAtIso,
        soldPrice: soldPrice,
        soldAtIso: soldAtIso,
      );

  /// Copia com a venda registrada, ou desfeita se [price] for null.
  PieceRecord withSale(double? price, String? atIso) => PieceRecord(
        id: id,
        pieceName: pieceName,
        fabricUsages: fabricUsages,
        additionalMaterialsCost: additionalMaterialsCost,
        laborHours: laborHours,
        hourlyValue: hourlyValue,
        laborCost: laborCost,
        operationalCost: operationalCost,
        productionCost: productionCost,
        suggestedPrice: suggestedPrice,
        createdAtIso: createdAtIso,
        soldPrice: price,
        soldAtIso: atIso,
        photoName: photoName,
      );

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
      'soldPrice': soldPrice,
      'soldAtIso': soldAtIso,
      'photoName': photoName,
    };
  }

  /// [fabricWidths] (id do tecido -> largura) so e usado para converter
  /// registros antigos, que não guardavam a largura do rolo.
  factory PieceRecord.fromJson(
    Map<String, dynamic> json, {
    Map<String, double> fabricWidths = const <String, double>{},
  }) {
    // Compatibilidade com registros antigos (formato pre-refatoracao):
    // se existir 'fabricId' no JSON, converte para FabricUsage unico.
    List<FabricUsage> usages;
    if (json.containsKey('fabricUsages')) {
      usages = (json['fabricUsages'] as List<dynamic>)
          .map((dynamic e) => FabricUsage.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final double usedWidth = (json['usedWidthMeters'] as num).toDouble();
      final double usedLength = (json['usedLengthMeters'] as num).toDouble();
      final double rollWidth = fabricWidths[json['fabricId']] ?? 1;
      final double linear =
          rollWidth > 0 ? usedWidth * usedLength / rollWidth : 0;
      usages = <FabricUsage>[
        FabricUsage(
          fabricId: json['fabricId'] as String,
          fabricName: json['fabricName'] as String,
          fabricWidthMeters: rollWidth,
          fabricPricePerMeter: linear > 0
              ? (json['fabricCost'] as num).toDouble() / linear
              : 0,
          usedWidthMeters: usedWidth,
          usedLengthMeters: usedLength,
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
      soldPrice: (json['soldPrice'] as num?)?.toDouble(),
      soldAtIso: json['soldAtIso'] as String?,
      photoName: json['photoName'] as String?,
    );
  }
}
