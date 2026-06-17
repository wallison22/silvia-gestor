import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/parsing.dart';
import '../../models/business_config.dart';
import '../../models/pricing_breakdown.dart';
import '../../services/pricing_service.dart';

const Color _kPrimary = Color(0xFF1E40AF);
const Color _kAccent = Color(0xFFF59E0B);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextMid = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    required this.config,
    required this.currency,
    required this.onSaveConfig,
    super.key,
  });

  final BusinessConfig config;
  final NumberFormat currency;
  final void Function(BusinessConfig config) onSaveConfig;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _salaryController;
  late final TextEditingController _hoursController;
  late final TextEditingController _fixedController;
  late final TextEditingController _profitController;

  @override
  void initState() {
    super.initState();
    _salaryController = TextEditingController(
      text: widget.config.desiredMonthlySalary.toString(),
    );
    _hoursController = TextEditingController(
      text: widget.config.monthlyWorkHours.toString(),
    );
    _fixedController = TextEditingController(
      text: widget.config.fixedCostPercent.toString(),
    );
    _profitController = TextEditingController(
      text: widget.config.profitPercent.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _salaryController.text = widget.config.desiredMonthlySalary.toString();
      _hoursController.text = widget.config.monthlyWorkHours.toString();
      _fixedController.text = widget.config.fixedCostPercent.toString();
      _profitController.text = widget.config.profitPercent.toString();
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _hoursController.dispose();
    _fixedController.dispose();
    _profitController.dispose();
    super.dispose();
  }

  void _save() {
    final BusinessConfig updated = BusinessConfig(
      desiredMonthlySalary: parseDouble(_salaryController.text),
      monthlyWorkHours: parseDouble(_hoursController.text),
      fixedCostPercent: parseDouble(_fixedController.text),
      profitPercent: parseDouble(_profitController.text),
    );
    widget.onSaveConfig(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: <Widget>[
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Configuracoes salvas!'),
          ],
        ),
        backgroundColor: _kPrimary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PricingBreakdown sample = calculatePricing(
      config: widget.config,
      laborHours: 3,
      materialsCost: 75,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: <Widget>[
        // ── Cabeçalho ────────────────────────────────────────────────────────
        const _GradientCard(
          gradient: <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
          icon: Icons.tune_rounded,
          title: 'Configuracoes do Negocio',
          subtitle:
              'Defina sua remuneracao, horas trabalhadas e margens para que o app calcule o preco ideal de cada peca.',
        ),
        const SizedBox(height: 20),

        // ── Remuneracao ───────────────────────────────────────────────────────
        const _SectionBar(
            label: 'Remuneracao',
            icon: Icons.payments_outlined,
            color: _kPrimary),
        const SizedBox(height: 10),
        _GroupBox(
          children: <Widget>[
            TextField(
              controller: _salaryController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Salario mensal desejado (R\$)',
                prefixIcon: Icon(Icons.attach_money_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hoursController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Horas de trabalho por mes',
                helperText: 'Ex: 220 horas (8h/dia x 27,5 dias)',
                prefixIcon: Icon(Icons.access_time_outlined),
              ),
            ),
          ],
        ),

        // Valor da hora calculado em tempo real
        if (parseDouble(_hoursController.text) > 0) ...<Widget>[
          const SizedBox(height: 8),
          _InfoPill(
            icon: Icons.bolt_rounded,
            label:
                'Valor da hora: ${widget.currency.format(parseDouble(_salaryController.text) / parseDouble(_hoursController.text))}',
            color: _kPrimary,
          ),
        ],

        const SizedBox(height: 20),

        // ── Margens ───────────────────────────────────────────────────────────
        const _SectionBar(
            label: 'Margens',
            icon: Icons.percent_outlined,
            color: _kAccent),
        const SizedBox(height: 10),
        _GroupBox(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _fixedController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Custos fixos (%)',
                      helperText: 'Aluguel, energia...',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _profitController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Lucro (%)',
                      helperText: 'Margem de lucro',
                      prefixIcon: Icon(Icons.trending_up_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        const _InfoPill(
          icon: Icons.info_outline_rounded,
          label:
              'Margem: o lucro e calculado sobre o preco de venda, nao sobre o custo.',
          color: _kAccent,
        ),
        const SizedBox(height: 20),

        // ── Salvar ────────────────────────────────────────────────────────────
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Salvar configuracoes'),
        ),
        const SizedBox(height: 28),

        // ── Simulacao ─────────────────────────────────────────────────────────
        _SimulationCard(sample: sample, currency: widget.currency),
        const SizedBox(height: 28),

        // ── Rodape ────────────────────────────────────────────────────────────
        Center(
          child: Column(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.content_cut_rounded,
                    color: _kPrimary, size: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'SilviaTextil',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Componentes
// ─────────────────────────────────────────────────────────────────────────────

class _GradientCard extends StatelessWidget {
  const _GradientCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.2)),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: _kTextMid, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionBar extends StatelessWidget {
  const _SectionBar(
      {required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 18,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: color, fontSize: 14)),
      ],
    );
  }
}

class _GroupBox extends StatelessWidget {
  const _GroupBox({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const <BoxShadow>[
          BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SimulationCard extends StatelessWidget {
  const _SimulationCard(
      {required this.sample, required this.currency});
  final PricingBreakdown sample;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFFB45309), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.science_outlined,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Simulacao',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        Text('3h de trabalho + R\$ 75,00 em materiais',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _SimRow(
                      label: 'Valor da hora',
                      value: currency.format(sample.hourlyValue)),
                  _SimRow(
                      label: 'Custo de trabalho',
                      value: currency.format(sample.laborCost)),
                  _SimRow(
                      label: 'Custo operacional',
                      value: currency.format(sample.operationalCost)),
                  _SimRow(
                      label: 'Custo de producao',
                      value: currency.format(sample.productionCost)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _SimRow(
                    label: 'Preco final sugerido',
                    value: currency.format(sample.suggestedPrice),
                    bold: true,
                    color: const Color(0xFF059669),
                    large: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimRow extends StatelessWidget {
  const _SimRow(
      {required this.label,
      required this.value,
      this.bold = false,
      this.color,
      this.large = false});
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      fontSize: large ? 16 : 13,
      color: color ?? (bold ? _kTextDark : _kTextMid),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
