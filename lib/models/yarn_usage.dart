/// Uso de uma linha específica dentro de uma peça de crochê.
///
/// Custo = gramas_usadas × preço_por_grama
class YarnUsage {
  YarnUsage({
    required this.yarnId,
    required this.yarnName,
    required this.yarnPricePerGram,
    required this.usedWeightGrams,
  });

  final String yarnId;
  final String yarnName;

  /// Preço por grama snapshot do momento do registro.
  final double yarnPricePerGram;

  /// Gramas consumidas nesta peça.
  final double usedWeightGrams;

  double get cost => usedWeightGrams * yarnPricePerGram;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'yarnId': yarnId,
        'yarnName': yarnName,
        'yarnPricePerGram': yarnPricePerGram,
        'usedWeightGrams': usedWeightGrams,
      };

  factory YarnUsage.fromJson(Map<String, dynamic> json) => YarnUsage(
        yarnId: json['yarnId'] as String,
        yarnName: json['yarnName'] as String,
        yarnPricePerGram: (json['yarnPricePerGram'] as num).toDouble(),
        usedWeightGrams: (json['usedWeightGrams'] as num).toDouble(),
      );
}
