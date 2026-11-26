/// Para que o formulário de peça foi aberto.
enum PieceFormMode {
  create('Registrar peça'),
  edit('Editar peça'),
  duplicate('Duplicar peça'),

  /// Só calcula o preço; não mexe no estoque.
  quote('Orçamento');

  const PieceFormMode(this.title);
  final String title;
}

/// Limite de peças iguais registradas de uma vez.
const int kMaxQuantity = 100;

String? validateQuantity(double value) {
  if (value < 1 || value > kMaxQuantity || value != value.roundToDouble()) {
    return 'A quantidade deve ser um número inteiro de 1 a $kMaxQuantity.';
  }
  return null;
}
