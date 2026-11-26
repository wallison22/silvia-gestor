import 'piece_form_mode.dart';
import 'yarn_usage.dart';

class CreateCrochetPieceInput {
  CreateCrochetPieceInput({
    required this.pieceName,
    required this.yarnUsages,
    required this.otherMaterialsCost,
    required this.laborHours,
    this.quantity = 1,
    this.photoName,
  });

  final String pieceName;
  final List<YarnUsage> yarnUsages;
  final double otherMaterialsCost;
  final double laborHours;

  /// Quantas peças iguais registrar; os demais campos são de UMA peça.
  final double quantity;
  final String? photoName;

  String? validate({bool requireMaterials = true}) {
    if (pieceName.trim().isEmpty) return 'Informe o nome da peça.';
    final String? quantityError = validateQuantity(quantity);
    if (quantityError != null) return quantityError;
    if (requireMaterials && yarnUsages.isEmpty) return 'Adicione ao menos uma linha à peça.';
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
