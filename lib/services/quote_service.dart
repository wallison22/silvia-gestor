import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Abre o compartilhamento do celular (WhatsApp etc.). Trocável em testes.
Future<void> Function(String text) shareText = (String text) async {
  await SharePlus.instance.share(ShareParams(text: text));
};

/// Texto do orçamento para a cliente. Nunca inclui custos nem lucro.
String buildQuoteText({
  required String pieceName,
  required double unitPrice,
  required int quantity,
  required NumberFormat currency,
}) {
  final String unit = currency.format(unitPrice);
  if (quantity == 1) return '*Orçamento*\n$pieceName\nValor: $unit';
  return '*Orçamento*\n$pieceName\n'
      'Quantidade: $quantity\n'
      'Valor de cada: $unit\n'
      'Total: ${currency.format(unitPrice * quantity)}';
}
