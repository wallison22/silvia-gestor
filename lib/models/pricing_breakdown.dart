class PricingBreakdown {
  PricingBreakdown({
    required this.hourlyValue,
    required this.laborCost,
    required this.operationalCost,
    required this.productionCost,
    required this.suggestedPrice,
  });

  final double hourlyValue;
  final double laborCost;
  final double operationalCost;
  final double productionCost;
  final double suggestedPrice;
}
