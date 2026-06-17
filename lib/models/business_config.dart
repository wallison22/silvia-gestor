class BusinessConfig {
  BusinessConfig({
    required this.desiredMonthlySalary,
    required this.monthlyWorkHours,
    required this.fixedCostPercent,
    required this.profitPercent,
  });

  final double desiredMonthlySalary;
  final double monthlyWorkHours;
  final double fixedCostPercent;
  final double profitPercent;

  factory BusinessConfig.defaults() {
    return BusinessConfig(
      desiredMonthlySalary: 4000,
      monthlyWorkHours: 220,
      fixedCostPercent: 15,
      profitPercent: 20,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'desiredMonthlySalary': desiredMonthlySalary,
      'monthlyWorkHours': monthlyWorkHours,
      'fixedCostPercent': fixedCostPercent,
      'profitPercent': profitPercent,
    };
  }

  factory BusinessConfig.fromJson(Map<String, dynamic> json) {
    return BusinessConfig(
      desiredMonthlySalary: (json['desiredMonthlySalary'] as num).toDouble(),
      monthlyWorkHours: (json['monthlyWorkHours'] as num).toDouble(),
      fixedCostPercent: (json['fixedCostPercent'] as num).toDouble(),
      profitPercent: (json['profitPercent'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BusinessConfig &&
        desiredMonthlySalary == other.desiredMonthlySalary &&
        monthlyWorkHours == other.monthlyWorkHours &&
        fixedCostPercent == other.fixedCostPercent &&
        profitPercent == other.profitPercent;
  }

  @override
  int get hashCode => Object.hash(
        desiredMonthlySalary,
        monthlyWorkHours,
        fixedCostPercent,
        profitPercent,
      );
}
