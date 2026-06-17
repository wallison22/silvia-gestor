double parseDouble(String value) {
  final String normalized = value.replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? 0;
}
