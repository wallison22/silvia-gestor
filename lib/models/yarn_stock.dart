class YarnStock {
  YarnStock({
    required this.id,
    required this.name,
    required this.storeName,
    required this.skeinWeightGrams,
    required this.skeinPrice,
    required this.stockWeightGrams,
    required this.createdAtIso,
  });

  final String id;
  final String name;
  final String storeName;

  /// Peso do novelo/carretel original em gramas.
  final double skeinWeightGrams;

  /// Preço pago pelo novelo/carretel.
  final double skeinPrice;

  /// Peso restante em estoque (gramas).
  final double stockWeightGrams;

  final String createdAtIso;

  double get pricePerGram =>
      skeinWeightGrams > 0 ? skeinPrice / skeinWeightGrams : 0;

  double get stockValue => stockWeightGrams * pricePerGram;

  YarnStock copyWith({
    String? id,
    String? name,
    String? storeName,
    double? skeinWeightGrams,
    double? skeinPrice,
    double? stockWeightGrams,
    String? createdAtIso,
  }) {
    return YarnStock(
      id: id ?? this.id,
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      skeinWeightGrams: skeinWeightGrams ?? this.skeinWeightGrams,
      skeinPrice: skeinPrice ?? this.skeinPrice,
      stockWeightGrams: stockWeightGrams ?? this.stockWeightGrams,
      createdAtIso: createdAtIso ?? this.createdAtIso,
    );
  }

  String? validate() {
    if (name.trim().isEmpty) return 'Informe o nome da linha.';
    if (skeinWeightGrams <= 0) return 'O peso do novelo deve ser maior que zero.';
    if (skeinPrice < 0) return 'O preço não pode ser negativo.';
    if (stockWeightGrams < 0) return 'O estoque não pode ser negativo.';
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'storeName': storeName,
        'skeinWeightGrams': skeinWeightGrams,
        'skeinPrice': skeinPrice,
        'stockWeightGrams': stockWeightGrams,
        'createdAtIso': createdAtIso,
      };

  factory YarnStock.fromJson(Map<String, dynamic> json) => YarnStock(
        id: json['id'] as String,
        name: json['name'] as String,
        storeName: (json['storeName'] ?? '') as String,
        skeinWeightGrams: (json['skeinWeightGrams'] as num).toDouble(),
        skeinPrice: (json['skeinPrice'] as num).toDouble(),
        stockWeightGrams: (json['stockWeightGrams'] as num).toDouble(),
        createdAtIso: json['createdAtIso'] as String,
      );
}
