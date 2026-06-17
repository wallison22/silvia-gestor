import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/parsing.dart';
import '../../models/business_config.dart';
import '../../models/create_piece_input.dart';
import '../../models/fabric_stock.dart';
import '../../models/fabric_usage.dart';
import '../../models/piece_record.dart';
import '../../models/pricing_breakdown.dart';
import '../../services/pricing_service.dart';

// Cores compartilhadas
const Color _kPrimary = Color(0xFF1E40AF);
const Color _kAccent = Color(0xFFF59E0B);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextMid = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kBg = Color(0xFFF8FAFC);

class PiecesTab extends StatelessWidget {
  const PiecesTab({
    required this.pieces,
    required this.fabrics,
    required this.config,
    required this.currency,
    required this.onCreatePiece,
    required this.onDeletePiece,
    super.key,
  });

  final List<PieceRecord> pieces;
  final List<FabricStock> fabrics;
  final BusinessConfig config;
  final NumberFormat currency;
  final void Function(CreatePieceInput input) onCreatePiece;
  final void Function(String id) onDeletePiece;

  @override
  Widget build(BuildContext context) {
    final double totalRevenue =
        pieces.fold(0, (double s, PieceRecord p) => s + p.suggestedPrice);
    final double totalCost =
        pieces.fold(0, (double s, PieceRecord p) => s + p.productionCost);

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            _DashboardCard(
              title: 'Pecas Registradas',
              icon: Icons.content_cut_rounded,
              gradient: const <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
              stats: <_StatData>[
                _StatData(
                  icon: Icons.layers_rounded,
                  label: 'Pecas',
                  value: '${pieces.length}',
                  color: _kPrimary,
                ),
                _StatData(
                  icon: Icons.receipt_long_rounded,
                  label: 'Custo total',
                  value: currency.format(totalCost),
                  color: const Color(0xFF7C3AED),
                ),
                _StatData(
                  icon: Icons.trending_up_rounded,
                  label: 'Receita',
                  value: currency.format(totalRevenue),
                  color: const Color(0xFF059669),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (pieces.isEmpty)
              const _EmptyState(
                icon: Icons.content_cut_outlined,
                title: 'Nenhuma peca ainda',
                subtitle: 'Toque em + para registrar sua primeira peca.',
              )
            else
              ...pieces.map((PieceRecord p) => _PieceCard(
                    piece: p,
                    currency: currency,
                    onTap: () => _showPieceDetails(context, p, currency),
                    onDelete: () =>
                        _confirmDelete(context, p, onDeletePiece),
                  )),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: fabrics.isEmpty
                ? null
                : () => showPieceFormSheet(
                      context,
                      fabrics: fabrics,
                      config: config,
                      currency: currency,
                      onSave: onCreatePiece,
                    ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar peca'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Componentes compartilhados de design
// ─────────────────────────────────────────────────────────────────────────────

class _StatData {
  const _StatData(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.stats,
  });
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final List<_StatData> stats;

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
          children: <Widget>[
            Container(
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
              padding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: stats.map((s) => _StatTile(data: s)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(data.icon, color: data.color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(data.value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: _kTextDark,
                letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text(data.label,
            style:
                const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 40, color: const Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de peca
// ─────────────────────────────────────────────────────────────────────────────

class _PieceCard extends StatelessWidget {
  const _PieceCard({
    required this.piece,
    required this.currency,
    required this.onTap,
    required this.onDelete,
  });
  final PieceRecord piece;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: <Widget>[
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                _kPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.content_cut_rounded,
                              color: _kPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(piece.pieceName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: _kTextDark)),
                              if (piece.fabricsDescription.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 3),
                                Text(piece.fabricsDescription,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: _kTextMid),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  _PriceBadge(
                                    label: 'Custo',
                                    value:
                                        currency.format(piece.productionCost),
                                    color: const Color(0xFF7C3AED),
                                  ),
                                  const SizedBox(width: 8),
                                  _PriceBadge(
                                    label: 'Preco',
                                    value: currency
                                        .format(piece.suggestedPrice),
                                    color: const Color(0xFF059669),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 20),
                          color: const Color(0xFFFCA5A5),
                          onPressed: onDelete,
                          tooltip: 'Excluir',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario de registro de peca
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showPieceFormSheet(
  BuildContext context, {
  required List<FabricStock> fabrics,
  required BusinessConfig config,
  required NumberFormat currency,
  required void Function(CreatePieceInput input) onSave,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) => _PieceFormSheet(
      fabrics: fabrics,
      config: config,
      currency: currency,
      onSave: onSave,
    ),
  );
}

class _FabricRow {
  _FabricRow(String id)
      : fabricId = id,
        widthCtrl = TextEditingController(),
        lengthCtrl = TextEditingController();
  String fabricId;
  final TextEditingController widthCtrl;
  final TextEditingController lengthCtrl;
  void dispose() {
    widthCtrl.dispose();
    lengthCtrl.dispose();
  }
}

class _PieceFormSheet extends StatefulWidget {
  const _PieceFormSheet({
    required this.fabrics,
    required this.config,
    required this.currency,
    required this.onSave,
  });
  final List<FabricStock> fabrics;
  final BusinessConfig config;
  final NumberFormat currency;
  final void Function(CreatePieceInput) onSave;

  @override
  State<_PieceFormSheet> createState() => _PieceFormSheetState();
}

class _PieceFormSheetState extends State<_PieceFormSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _extraCtrl =
      TextEditingController(text: '0');
  final TextEditingController _laborCtrl = TextEditingController();
  late final List<_FabricRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = <_FabricRow>[_FabricRow(widget.fabrics.first.id)];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _extraCtrl.dispose();
    _laborCtrl.dispose();
    for (final _FabricRow r in _rows) { r.dispose(); }
    super.dispose();
  }

  List<FabricUsage> _buildUsages() => _rows.map((_FabricRow row) {
        final FabricStock f = widget.fabrics
            .firstWhere((FabricStock x) => x.id == row.fabricId);
        return FabricUsage(
          fabricId: f.id,
          fabricName: f.name,
          fabricWidthMeters: f.widthMeters,
          fabricPricePerMeter: f.pricePerMeter,
          usedWidthMeters: parseDouble(row.widthCtrl.text),
          usedLengthMeters: parseDouble(row.lengthCtrl.text),
        );
      }).toList();

  @override
  Widget build(BuildContext context) {
    final List<FabricUsage> usages = _buildUsages();
    final double totalFabric =
        usages.fold(0, (double s, FabricUsage u) => s + u.fabricCost);
    final double extra = parseDouble(_extraCtrl.text);
    final double hours = parseDouble(_laborCtrl.text);
    final PricingBreakdown preview = calculatePricing(
      config: widget.config,
      laborHours: hours,
      materialsCost: totalFabric + extra,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.content_cut_rounded,
                      color: _kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Registrar Peca',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome da peca',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 20),
            const _FormSection(label: 'Tecidos utilizados', color: _kPrimary),
            const SizedBox(height: 10),
            ..._rows.asMap().entries.map((MapEntry<int, _FabricRow> e) {
              final int i = e.key;
              final _FabricRow row = e.value;
              final FabricStock fabric = widget.fabrics
                  .firstWhere((FabricStock f) => f.id == row.fabricId);
              final FabricUsage usage = FabricUsage(
                fabricId: fabric.id,
                fabricName: fabric.name,
                fabricWidthMeters: fabric.widthMeters,
                fabricPricePerMeter: fabric.pricePerMeter,
                usedWidthMeters: parseDouble(row.widthCtrl.text),
                usedLengthMeters: parseDouble(row.lengthCtrl.text),
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: row.fabricId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Tecido',
                              prefixIcon:
                                  const Icon(Icons.layers_outlined),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: _kBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: _kBorder),
                              ),
                              isDense: true,
                            ),
                            items: widget.fabrics
                                .map((FabricStock f) =>
                                    DropdownMenuItem<String>(
                                      value: f.id,
                                      child: Text(
                                          '${f.name} (${f.stockLengthMeters.toStringAsFixed(2)}m)',
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (String? v) {
                              if (v != null) {
                                setState(() => row.fabricId = v);
                              }
                            },
                          ),
                        ),
                        if (_rows.length > 1) ...<Widget>[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Color(0xFFEF4444)),
                            onPressed: () => setState(() {
                              _rows[i].dispose();
                              _rows.removeAt(i);
                            }),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: row.widthCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Largura (m)',
                              helperText:
                                  'Max ${fabric.widthMeters.toStringAsFixed(2)}m',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: _kBorder),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: row.lengthCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Comprimento (m)',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: _kBorder),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (usage.usedAreaSquareMeters > 0) ...<Widget>[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Area: ${usage.usedAreaSquareMeters.toStringAsFixed(2)} m²'
                          '  ·  Consumo: ${usage.equivalentLengthUsedMeters.toStringAsFixed(2)}m'
                          '  ·  Custo: ${widget.currency.format(usage.fabricCost)}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: _kPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(
                  () => _rows.add(_FabricRow(widget.fabrics.first.id))),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Adicionar outro tecido'),
            ),
            const SizedBox(height: 16),
            const _FormSection(label: 'Outros custos', color: _kAccent),
            const SizedBox(height: 10),
            TextField(
              controller: _extraCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Aviamentos e materiais (R\$)',
                prefixIcon: Icon(Icons.attach_money_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _laborCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Tempo gasto (horas)',
                helperText: 'Ex: 1.5 = 1h 30min',
                prefixIcon: Icon(Icons.access_time_outlined),
              ),
            ),
            const SizedBox(height: 16),
            _PricingPreviewCard(preview: preview, currency: widget.currency,
                totalFabric: totalFabric, extra: extra),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                final CreatePieceInput input = CreatePieceInput(
                  pieceName: _nameCtrl.text.trim(),
                  fabricUsages: _buildUsages(),
                  additionalMaterialsCost: parseDouble(_extraCtrl.text),
                  laborHours: parseDouble(_laborCtrl.text),
                );
                final String? err = input.validate();
                if (err != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err)));
                  return;
                }
                widget.onSave(input);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Salvar peca'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview de precificacao
// ─────────────────────────────────────────────────────────────────────────────

class _PricingPreviewCard extends StatelessWidget {
  const _PricingPreviewCard({
    required this.preview,
    required this.currency,
    required this.totalFabric,
    required this.extra,
  });
  final PricingBreakdown preview;
  final NumberFormat currency;
  final double totalFabric;
  final double extra;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: <Widget>[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.calculate_outlined,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Preview de precificacao',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: <Widget>[
                _PRow('Tecidos', currency.format(totalFabric)),
                _PRow('Aviamentos', currency.format(extra)),
                _PRow('Total materiais',
                    currency.format(totalFabric + extra),
                    bold: true),
                const Divider(height: 16),
                _PRow('Valor da hora',
                    currency.format(preview.hourlyValue)),
                _PRow('Custo de trabalho',
                    currency.format(preview.laborCost)),
                _PRow('Custo operacional',
                    currency.format(preview.operationalCost)),
                _PRow('Custo de producao',
                    currency.format(preview.productionCost),
                    bold: true),
                const Divider(height: 16),
                _PRow('Preco sugerido',
                    currency.format(preview.suggestedPrice),
                    bold: true,
                    color: const Color(0xFF059669),
                    large: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PRow extends StatelessWidget {
  const _PRow(this.label, this.value,
      {this.bold = false, this.color, this.large = false});
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final TextStyle s = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      fontSize: large ? 16 : 13,
      color: color ?? (bold ? _kTextDark : _kTextMid),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(child: Text(label, style: s)),
          Text(value, style: s),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detalhes da peca
// ─────────────────────────────────────────────────────────────────────────────

void _showPieceDetails(
    BuildContext context, PieceRecord piece, NumberFormat currency) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.content_cut_rounded,
                      color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(piece.pieceName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: _kTextDark)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _FormSection(label: 'Tecidos usados', color: _kPrimary),
            const SizedBox(height: 10),
            ...piece.fabricUsages.map((FabricUsage u) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(u.fabricName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _kTextDark)),
                      const SizedBox(height: 4),
                      Text(
                        '${u.usedWidthMeters.toStringAsFixed(2)}m × ${u.usedLengthMeters.toStringAsFixed(2)}m'
                        ' = ${u.usedAreaSquareMeters.toStringAsFixed(2)} m²',
                        style:
                            const TextStyle(fontSize: 12, color: _kTextMid),
                      ),
                      Text(
                        'Consumo: ${u.equivalentLengthUsedMeters.toStringAsFixed(2)}m  ·  Custo: ${currency.format(u.fabricCost)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: _kPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const _FormSection(label: 'Custos', color: _kAccent),
            const SizedBox(height: 10),
            _PRow('Custo de tecidos',
                currency.format(piece.totalFabricCost)),
            _PRow('Aviamentos',
                currency.format(piece.additionalMaterialsCost)),
            _PRow('Total de materiais',
                currency.format(piece.totalMaterialsCost),
                bold: true),
            const SizedBox(height: 16),
            const _FormSection(
                label: 'Precificacao (4 pilares)', color: _kPrimary),
            const SizedBox(height: 10),
            _PRow('Valor da hora', currency.format(piece.hourlyValue)),
            _PRow(
                'Trabalho (${piece.laborHours.toStringAsFixed(2)}h)',
                currency.format(piece.laborCost)),
            _PRow('Custo operacional',
                currency.format(piece.operationalCost)),
            _PRow('Custo de producao',
                currency.format(piece.productionCost),
                bold: true),
            const Divider(height: 24),
            _PRow('Preco final sugerido',
                currency.format(piece.suggestedPrice),
                bold: true,
                color: const Color(0xFF059669),
                large: true),
          ],
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirmar exclusao
// ─────────────────────────────────────────────────────────────────────────────

void _confirmDelete(
  BuildContext context,
  PieceRecord piece,
  void Function(String) onDelete,
) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.delete_outline_rounded,
          color: Color(0xFFEF4444), size: 36),
      title: const Text('Excluir peca',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text(
          'Deseja excluir "${piece.pieceName}"?\nO consumo dos tecidos sera devolvido ao estoque.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444)),
          onPressed: () {
            onDelete(piece.id);
            Navigator.pop(ctx);
          },
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
}
