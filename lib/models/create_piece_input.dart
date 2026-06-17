import 'fabric_usage.dart';

/// Entrada para criacao de uma nova peca.
///
/// Uma peca pode utilizar um ou mais tecidos do estoque.
class CreatePieceInput {
  CreatePieceInput({
    required this.pieceName,
    required this.fabricUsages,
    required this.additionalMaterialsCost,
    required this.laborHours,
  });

  final String pieceName;

  /// Lista de tecidos usados nesta peca (deve ter ao menos 1 item).
  final List<FabricUsage> fabricUsages;

  /// Custo de aviamentos e outros materiais que nao sao tecido (R$).
  final double additionalMaterialsCost;

  /// Tempo total de producao em horas decimais.
  final double laborHours;

  String? validate() {
    if (pieceName.trim().isEmpty) {
      return 'Informe o nome da peca.';
    }
    if (fabricUsages.isEmpty) {
      return 'Adicione ao menos um tecido a peca.';
    }
    for (final FabricUsage u in fabricUsages) {
      if (u.usedWidthMeters <= 0 || u.usedLengthMeters <= 0) {
        return 'Informe largura e comprimento validos para o tecido "${u.fabricName}".';
      }
      if (u.usedWidthMeters > u.fabricWidthMeters) {
        return 'A largura usada (${u.usedWidthMeters.toStringAsFixed(2)}m) '
            'excede a largura do tecido "${u.fabricName}" '
            '(${u.fabricWidthMeters.toStringAsFixed(2)}m).';
      }
    }
    if (additionalMaterialsCost < 0) {
      return 'O custo adicional de materiais nao pode ser negativo.';
    }
    if (laborHours < 0) {
      return 'O tempo gasto nao pode ser negativo.';
    }
    return null;
  }
}
