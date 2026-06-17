import 'yarn_usage.dart';

class CreateCrochetPieceInput {
  CreateCrochetPieceInput({
    required this.pieceName,
    required this.yarnUsages,
    required this.otherMaterialsCost,
    required this.laborHours,
  });

  final String pieceName;
  final List<YarnUsage> yarnUsages;
  final double otherMaterialsCost;
  final double laborHours;

  String? validate() {
    if (pieceName.trim().isEmpty) return 'Informe o nome da peça.';
    if (yarnUsages.isEmpty) return 'Adicione ao menos uma linha à peça.';
    for (final YarnUsage u in yarnUsages) {
      if (u.usedWeightGrams <= 0) {
        return 'Informe a quantidade em gramas da linha "${u.yarnName}".';
      }
    }
    if (otherMaterialsCost < 0) {
      return 'O custo de outros materiais não pode ser negativo.';
    }
    if (laborHours < 0) return 'O tempo gasto não pode ser negativo.';
    return null;
  }
}
