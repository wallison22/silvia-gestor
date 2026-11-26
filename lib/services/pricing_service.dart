import '../models/business_config.dart';
import '../models/pricing_breakdown.dart';

/// Arredonda para centavos.
double roundCents(double value) => (value * 100 + 1e-7).round() / 100;

/// Preço = custo de produção / (1 - margem). O lucro e margem sobre a venda.
///
/// O preço parte do custo exato; so os resultados são arredondados, para que o total
/// das peças bata com a soma dos valores exibidos.
PricingBreakdown calculatePricing({
  required BusinessConfig config,
  required double laborHours,
  required double materialsCost,
}) {
  // Config invalida e barrada por BusinessConfig.validate() ao salvar; aqui so
  // evitamos divisao por zero na previa.
  final double hourlyValue = config.monthlyWorkHours <= 0
      ? 0
      : config.desiredMonthlySalary / config.monthlyWorkHours;
  final double laborCost = laborHours * hourlyValue;
  final double operationalCost =
      laborCost + (laborCost * (config.fixedCostPercent / 100));
  final double productionCost = operationalCost + materialsCost;
  final double margin = (config.profitPercent / 100).clamp(0.0, 0.9999);
  final double suggestedPrice = roundCents(productionCost / (1 - margin));

  return PricingBreakdown(
    hourlyValue: hourlyValue,
    laborCost: laborCost,
    operationalCost: operationalCost,
    productionCost: roundCents(productionCost),
    suggestedPrice: suggestedPrice,
  );
}
