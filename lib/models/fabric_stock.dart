class FabricStock {
  FabricStock({
    required this.id,
    required this.name,
    required this.storeName,
    required this.widthMeters,
    required this.stockLengthMeters,
    required this.pricePerMeter,
    required this.createdAtIso,
  });

  final String id;
  final String name;
  final String storeName;
  final double widthMeters;
  final double stockLengthMeters;
  final double pricePerMeter;
  final String createdAtIso;

  double get areaInStockSquareMeters => widthMeters * stockLengthMeters;

  FabricStock copyWith({
    String? id,
    String? name,
    String? storeName,
    double? widthMeters,
    double? stockLengthMeters,
    double? pricePerMeter,
    String? createdAtIso,
  }) {
    return FabricStock(
      id: id ?? this.id,
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      widthMeters: widthMeters ?? this.widthMeters,
      stockLengthMeters: stockLengthMeters ?? this.stockLengthMeters,
      pricePerMeter: pricePerMeter ?? this.pricePerMeter,
      createdAtIso: createdAtIso ?? this.createdAtIso,
    );
  }

  String? validate() {
    if (name.trim().isEmpty) {
      return 'Informe o nome do tecido.';
    }
    if (widthMeters <= 0) {
      return 'A largura do tecido deve ser maior que zero.';
    }
    if (widthMeters < 0.2) {
      return 'Largura muito pequena. Digite em centímetros (ex: 140).';
    }
    if (stockLengthMeters < 0) {
      return 'O estoque não pode ser negativo.';
    }
    if (pricePerMeter < 0) {
      return 'O preço por metro não pode ser negativo.';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'storeName': storeName,
      'widthMeters': widthMeters,
      'stockLengthMeters': stockLengthMeters,
      'pricePerMeter': pricePerMeter,
      'createdAtIso': createdAtIso,
    };
  }

  factory FabricStock.fromJson(Map<String, dynamic> json) {
    return FabricStock(
      id: json['id'] as String,
      name: json['name'] as String,
      storeName: (json['storeName'] ?? '') as String,
      widthMeters: (json['widthMeters'] as num).toDouble(),
      stockLengthMeters: (json['stockLengthMeters'] as num).toDouble(),
      pricePerMeter: (json['pricePerMeter'] as num).toDouble(),
      createdAtIso: json['createdAtIso'] as String,
    );
  }
}
