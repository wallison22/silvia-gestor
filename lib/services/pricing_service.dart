import '../models/business_config.dart';
import '../models/pricing_breakdown.dart';

PricingBreakdown calculatePricing({
  required BusinessConfig config,
  required double laborHours,
  required double materialsCost,
}) {
  final double monthlyHours =
      config.monthlyWorkHours <= 0 ? 1 : config.monthlyWorkHours;
  final double hourlyValue = config.desiredMonthlySalary / monthlyHours;
  final double laborCost = laborHours * hourlyValue;
  final double operationalCost =
      laborCost + (laborCost * (config.fixedCostPercent / 100));
  final double productionCost = operationalCost + materialsCost;
  final double margin = (config.profitPercent / 100).clamp(0.0, 0.9999);
  final double suggestedPrice = productionCost / (1 - margin);

  return PricingBreakdown(
    hourlyValue: hourlyValue,
    laborCost: laborCost,
    operationalCost: operationalCost,
    productionCost: productionCost,
    suggestedPrice: suggestedPrice,
  );
}
