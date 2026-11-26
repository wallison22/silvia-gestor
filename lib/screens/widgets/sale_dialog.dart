import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/parsing.dart';
import '../../services/pricing_service.dart';
import 'form_error.dart';

/// Pergunta por quanto a peça foi vendida. Retorna null se cancelado.
Future<double?> promptSalePrice(
  BuildContext context, {
  required String pieceName,
  required double suggestedPrice,
  required double productionCost,
  required NumberFormat currency,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _SaleDialog(
      pieceName: pieceName,
      suggestedPrice: suggestedPrice,
      productionCost: productionCost,
      currency: currency,
    ),
  );
}

/// Confirma a volta de uma peça vendida para o estoque de peças.
Future<bool> confirmUndoSale(BuildContext context, String pieceName) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: const Text('Desfazer venda'),
      content: Text('"$pieceName" voltará a constar como não vendida.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Desfazer'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _SaleDialog extends StatefulWidget {
  const _SaleDialog({
    required this.pieceName,
    required this.suggestedPrice,
    required this.productionCost,
    required this.currency,
  });

  final String pieceName;
  final double suggestedPrice;
  final double productionCost;
  final NumberFormat currency;

  @override
  State<_SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<_SaleDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: formatNumber(roundCents(widget.suggestedPrice)));
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final FormReader reader = FormReader();
    final double price =
        reader.number('Valor da venda', _ctrl.text, thousands: true);
    final String? error = reader.error ??
        (price < 0 ? 'O valor da venda não pode ser negativo.' : null);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, roundCents(price));
  }

  @override
  Widget build(BuildContext context) {
    final double? price = tryParseNumber(_ctrl.text, thousands: true);
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Registrar venda'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(widget.pieceName),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Valor da venda (R\$)',
              helperText:
                  'Sugerido: ${widget.currency.format(widget.suggestedPrice)}',
            ),
          ),
          const SizedBox(height: 12),
          if (price != null && price < widget.productionCost)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Abaixo do custo da peça '
                '(${widget.currency.format(widget.productionCost)}).',
                style: const TextStyle(
                    color: Color(0xFFC2410C), fontWeight: FontWeight.w600),
              ),
            ),
          FormError(_error),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Confirmar venda'),
        ),
      ],
    );
  }
}
