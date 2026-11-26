/// Maior valor aceito em qualquer campo (protege contra digitacao absurda).
const double _kMaxValue = 1e9;

/// Le um número digitado no padrão brasileiro. Retorna null se for inválido.
///
/// Aceita "12,50", "12.50", "1.234,56" e "R$ 12,50".
/// Com [thousands] (dinheiro e gramas), "1.200" vale 1200; sem ele
/// (metros e horas), "1.200" vale 1,2.
double? tryParseNumber(String value, {bool thousands = false}) {
  final String text =
      value.replaceAll('R\$', '').replaceAll('%', '').replaceAll(RegExp(r'\s'), '');

  String? normalized;
  if (RegExp(r'^-?\d+$').hasMatch(text)) {
    normalized = text;
  } else if (RegExp(r'^-?\d{1,3}(\.\d{3})+,\d*$').hasMatch(text) ||
      RegExp(r'^-?\d{1,3}(\.\d{3}){2,}$').hasMatch(text) ||
      (thousands && RegExp(r'^-?[1-9]\d{0,2}\.\d{3}$').hasMatch(text))) {
    normalized = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^-?(\d+[.,]\d*|[.,]\d+)$').hasMatch(text)) {
    normalized = text.replaceAll(',', '.');
  }
  if (normalized == null) return null;
  if (normalized.endsWith('.')) normalized += '0';

  final double? result = double.tryParse(normalized);
  if (result == null || result.abs() > _kMaxValue) return null;
  return result;
}

/// Le um tempo em horas: "1,5", "1:30", "1h30", "2h" ou "45min".
double? tryParseHours(String value) {
  final String text = value.toLowerCase().replaceAll(RegExp(r'\s'), '');
  final RegExpMatch? hm =
      RegExp(r'^(\d{1,4})(?:h|:)(\d{1,2})?(?:m|min)?$').firstMatch(text);
  if (hm != null) {
    final int minutes = int.parse(hm.group(2) ?? '0');
    if (minutes >= 60) return null;
    return int.parse(hm.group(1)!) + minutes / 60;
  }
  final RegExpMatch? m = RegExp(r'^(\d{1,4})(?:m|min)$').firstMatch(text);
  if (m != null) return int.parse(m.group(1)!) / 60;
  return tryParseNumber(text);
}

/// Versao para previas em tempo real: campo inválido conta como zero.
/// Nunca usar para gravar dados; para isso use [FormReader].
double parseDouble(String value, {bool thousands = false}) =>
    tryParseNumber(value, thousands: thousands) ?? 0;

/// Formata um número para preencher um campo de edicao (virgula decimal).
String formatNumber(double value) => value
    .toStringAsFixed(6)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

/// Mostra um número com casas fixas e virgula decimal.
String formatFixed(double value, int digits) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

/// Le os campos de um formulario guardando o primeiro erro encontrado, para
/// que valor inválido ou em branco nunca seja gravado como zero.
class FormReader {
  String? error;

  double number(String label, String text,
      {bool thousands = false, bool emptyAsZero = false}) {
    if (emptyAsZero && text.trim().isEmpty) return 0;
    return _check(label, text, tryParseNumber(text, thousands: thousands));
  }

  /// Campo em centímetros; devolve em metros.
  double centimeters(String label, String text) =>
      number(label, text, thousands: true) / 100;

  double hours(String label, String text) =>
      _check(label, text, tryParseHours(text));

  double _check(String label, String text, double? value) {
    if (value == null) {
      error ??= text.trim().isEmpty
          ? 'Preencha o campo "$label" (use 0 se não houver).'
          : 'Valor inválido em "$label": $text';
    }
    return value ?? 0;
  }
}
