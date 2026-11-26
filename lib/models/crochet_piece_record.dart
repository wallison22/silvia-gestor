import 'yarn_usage.dart';

/// Registro imutável de uma peça de crochê produzida.
class CrochetPieceRecord {
  CrochetPieceRecord({
    required this.id,
    required this.pieceName,
    required this.yarnUsages,
    required this.otherMaterialsCost,
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
  final List<YarnUsage> yarnUsages;

  /// Custo de outros materiais (ex: pano de prato base).
  final double otherMaterialsCost;

  final double laborHours;
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
  CrochetPieceRecord withDetails(String name, String? photo) => CrochetPieceRecord(
        id: id,
        pieceName: name,
        photoName: photo,
        yarnUsages: yarnUsages,
        otherMaterialsCost: otherMaterialsCost,
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
  CrochetPieceRecord withSale(double? price, String? atIso) => CrochetPieceRecord(
        id: id,
        pieceName: pieceName,
        yarnUsages: yarnUsages,
        otherMaterialsCost: otherMaterialsCost,
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

  double get totalYarnCost =>
      yarnUsages.fold(0, (double s, YarnUsage u) => s + u.cost);

  double get totalMaterialsCost => totalYarnCost + otherMaterialsCost;

  String get yarnsDescription =>
      yarnUsages.map((YarnUsage u) => u.yarnName).toSet().join(', ');

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'pieceName': pieceName,
        'yarnUsages': yarnUsages.map((YarnUsage u) => u.toJson()).toList(),
        'otherMaterialsCost': otherMaterialsCost,
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

  factory CrochetPieceRecord.fromJson(Map<String, dynamic> json) =>
      CrochetPieceRecord(
        id: json['id'] as String,
        pieceName: json['pieceName'] as String,
        yarnUsages: (json['yarnUsages'] as List<dynamic>)
            .map((dynamic e) =>
                YarnUsage.fromJson(e as Map<String, dynamic>))
            .toList(),
        otherMaterialsCost: (json['otherMaterialsCost'] as num).toDouble(),
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
