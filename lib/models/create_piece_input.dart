import '../core/utils/parsing.dart';
import 'fabric_usage.dart';
import 'piece_form_mode.dart';

/// Entrada para criacao de uma nova peça.
///
/// Uma peça pode utilizar um ou mais tecidos do estoque.
class CreatePieceInput {
  CreatePieceInput({
    required this.pieceName,
    required this.fabricUsages,
    required this.additionalMaterialsCost,
    required this.laborHours,
    this.quantity = 1,
    this.photoName,
  });

  final String pieceName;

  /// Lista de tecidos usados nesta peça (deve ter ao menos 1 item).
  final List<FabricUsage> fabricUsages;

  /// Custo de aviamentos e outros materiais que não são tecido (R$).
  final double additionalMaterialsCost;

  /// Tempo total de produção em horas decimais.
  final double laborHours;

  /// Quantas peças iguais registrar; os demais campos são de UMA peça.
  final double quantity;
  final String? photoName;

  String? validate({bool requireMaterials = true}) {
    if (pieceName.trim().isEmpty) {
      return 'Informe o nome da peça.';
    }
    final String? quantityError = validateQuantity(quantity);
    if (quantityError != null) return quantityError;
    if (requireMaterials && fabricUsages.isEmpty) {
      return 'Adicione ao menos um tecido à peça.';
    }
    for (final FabricUsage u in fabricUsages) {
      if (u.usedWidthMeters <= 0 || u.usedLengthMeters <= 0) {
        return 'Informe largura e comprimento válidos para o tecido "${u.fabricName}".';
      }
      if (u.usedWidthMeters > u.fabricWidthMeters + 0.000001) {
        return 'A largura usada (${formatNumber(u.usedWidthMeters * 100)} cm) '
            'excede a largura do tecido "${u.fabricName}" '
            '(${formatNumber(u.fabricWidthMeters * 100)} cm).';
      }
    }
    if (additionalMaterialsCost < 0) {
      return 'O custo adicional de materiais não pode ser negativo.';
    }
    if (laborHours < 0) {
      return 'O tempo gasto não pode ser negativo.';
    }
    return null;
  }
}
