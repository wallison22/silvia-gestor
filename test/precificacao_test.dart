import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:silvia_gestor/core/utils/parsing.dart';
import 'package:silvia_gestor/models/business_config.dart';
import 'package:silvia_gestor/models/fabric_usage.dart';
import 'package:silvia_gestor/services/pricing_service.dart';

void main() {
  test('exemplo conferido a mao', () {
    final r = calculatePricing(
        config: BusinessConfig.defaults(), laborHours: 3, materialsCost: 75);
    // 4000/220=18,1818; x3=54,5455; +15%=62,7273; +75=137,7273; /0,8=172,16
    expect(r.hourlyValue, closeTo(18.1818, .0001));
    expect(r.laborCost, closeTo(54.5455, .0001));
    expect(r.operationalCost, closeTo(62.7273, .0001));
    expect(r.productionCost, 137.73);
    expect(r.suggestedPrice, 172.16);
  });

  test('20 mil simulacoes: lucro real bate com a margem, sem prejuizo', () {
    final Random rnd = Random(42);
    for (int i = 0; i < 20000; i++) {
      final cfg = BusinessConfig(
          desiredMonthlySalary: 500 + rnd.nextDouble() * 20000,
          monthlyWorkHours: 1 + rnd.nextDouble() * 700,
          fixedCostPercent: rnd.nextDouble() * 200,
          profitPercent: rnd.nextDouble() * 95);
      expect(cfg.validate(), isNull);
      final double h = rnd.nextDouble() * 80, m = rnd.nextDouble() * 3000;
      final r = calculatePricing(config: cfg, laborHours: h, materialsCost: m);
      final double cost = m +
          h * cfg.desiredMonthlySalary / cfg.monthlyWorkHours +
          h *
              cfg.desiredMonthlySalary /
              cfg.monthlyWorkHours *
              cfg.fixedCostPercent /
              100;
      expect(r.productionCost, closeTo(cost, .00501));
      expect(r.suggestedPrice * (1 - cfg.profitPercent / 100),
          closeTo(cost, .00501));
      expect(r.suggestedPrice, greaterThanOrEqualTo(r.productionCost));
      expect(
          r.suggestedPrice, double.parse(r.suggestedPrice.toStringAsFixed(2)));
    }
  });

  test('custo de tecido: rolo inteiro custa o preco do metro', () {
    FabricUsage u(double w, double l) => FabricUsage(
        fabricId: 'f',
        fabricName: 'f',
        fabricWidthMeters: 1.4,
        fabricPricePerMeter: 28,
        usedWidthMeters: w,
        usedLengthMeters: l);
    expect(u(1.4, 1).fabricCost, closeTo(28, 1e-9));
    expect(u(0.7, 1).fabricCost, closeTo(14, 1e-9));
    final b = FabricUsage.fromJson(jsonDecode(jsonEncode(u(0.7, 3).toJson())));
    expect(b.fabricCost, closeTo(42, 1e-9));
  });

  test('arredondamento de centavos', () {
    expect(roundCents(1.005), 1.01);
    expect(roundCents(0.1 + 0.2), 0.3);
    expect(roundCents(2.675), 2.68);
  });

  test('leitura de numeros', () {
    expect(tryParseNumber('1.500'), 1.5); // metros
    expect(tryParseNumber('1.500', thousands: true), 1500); // dinheiro
    expect(tryParseNumber('0.125', thousands: true), 0.125);
    expect(tryParseNumber('1.234.567,89'), 1234567.89);
    expect(tryParseNumber('15%'), 15);
    for (final String s in [
      '',
      '-',
      '.',
      ',',
      '1,2,3',
      '1.2,3',
      '1,234.56',
      '1e5',
      'NaN',
      'Infinity',
      '99999999999',
      '12abc'
    ]) {
      expect(tryParseNumber(s), isNull, reason: s);
      expect(tryParseNumber(s, thousands: true), isNull, reason: s);
    }
    expect(tryParseHours('45min'), 0.75);
    expect(tryParseHours('2h'), 2);
    expect(tryParseHours('1:75'), isNull);
  });

  test('valor mostrado para edicao volta identico', () {
    final Random rnd = Random(7);
    for (int i = 0; i < 20000; i++) {
      final double v =
          double.parse((rnd.nextDouble() * 5000).toStringAsFixed(i % 7));
      expect(tryParseNumber(formatNumber(v), thousands: true), v);
      expect(tryParseNumber(formatNumber(v)), v);
    }
  });
}
