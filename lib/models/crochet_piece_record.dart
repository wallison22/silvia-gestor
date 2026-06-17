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
      );
}
