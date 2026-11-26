import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/parsing.dart';
import '../../models/business_config.dart';
import '../../models/create_piece_input.dart';
import '../../models/fabric_stock.dart';
import '../../models/fabric_usage.dart';
import '../../models/piece_record.dart';
import '../../models/piece_form_mode.dart';
import '../../models/pricing_breakdown.dart';
import '../../services/pricing_service.dart';
import '../../services/quote_service.dart';
import 'form_error.dart';
import 'photo_field.dart';
import 'sale_dialog.dart';
import 'search_section.dart';

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
    required this.onUpdatePiece,
    required this.onDeletePiece,
    required this.onSetSale,
    super.key,
  });

  final List<PieceRecord> pieces;
  final List<FabricStock> fabrics;
  final BusinessConfig config;
  final NumberFormat currency;
  final String? Function(CreatePieceInput input) onCreatePiece;
  final String? Function(String id, CreatePieceInput input) onUpdatePiece;
  final void Function(String id) onDeletePiece;
  final void Function(String id, double? price) onSetSale;

  void _openForm(BuildContext context, PieceFormMode mode,
      [PieceRecord? piece]) {
    List<FabricStock> available = fabrics;
    if (mode == PieceFormMode.edit) {
      // O material da propria peça volta a contar como disponível.
      available = fabrics.map((FabricStock s) {
        final double back = piece!.fabricUsages
            .where((u) => u.fabricId == s.id)
            .fold(0, (double t, u) => t + u.equivalentLengthUsedMeters);
        return s.copyWith(stockLengthMeters: s.stockLengthMeters + back);
      }).toList();
    }
    showPieceFormSheet(
      context,
      fabrics: available,
      config: config,
      currency: currency,
      mode: mode,
      initial: piece,
      onSave: mode == PieceFormMode.edit
          ? (input) => onUpdatePiece(piece!.id, input)
          : onCreatePiece,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalRevenue =
        pieces.fold(0, (double s, PieceRecord p) => s + (p.isSold ? 0 : p.suggestedPrice));
    final double totalSold = pieces.fold(
        0, (double s, PieceRecord p) => s + (p.soldPrice ?? 0));
    final double totalCost =
        pieces.fold(0, (double s, PieceRecord p) => s + p.productionCost);

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            _DashboardCard(
              title: 'Peças Registradas',
              icon: Icons.content_cut_rounded,
              gradient: const <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
              stats: <_StatData>[
                _StatData(
                  icon: Icons.layers_rounded,
                  label: 'Peças',
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
                  label: 'A vender',
                  value: currency.format(totalRevenue),
                  color: const Color(0xFFF59E0B),
                ),
                _StatData(
                  icon: Icons.sell_rounded,
                  label: 'Vendido',
                  value: currency.format(totalSold),
                  color: const Color(0xFF059669),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openForm(context, PieceFormMode.quote),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Fazer orçamento'),
            ),
            const SizedBox(height: 16),
            if (pieces.isEmpty)
              const _EmptyState(
                icon: Icons.content_cut_outlined,
                title: 'Nenhuma peça ainda',
                subtitle: 'Toque em + para registrar sua primeira peça.',
              )
            else
              SearchSection<PieceRecord>(
                items: pieces.reversed.toList(),
                textOf: (PieceRecord p) => '${p.pieceName} ${p.fabricsDescription}',
                isSold: (PieceRecord p) => p.isSold,
                itemBuilder: (PieceRecord p) => _PieceCard(
                  piece: p,
                  currency: currency,
                  onTap: () => _showPieceDetails(
                    context,
                    p,
                    currency,
                    onEdit: () => _openForm(context, PieceFormMode.edit, p),
                    onDuplicate: fabrics.isEmpty
                        ? null
                        : () =>
                            _openForm(context, PieceFormMode.duplicate, p),
                  ),
                  onDelete: () => _confirmDelete(context, p, onDeletePiece),
                  onSale: () => _handleSale(context, p, currency, onSetSale),
                ),
              ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: fabrics.isEmpty
                ? null
                : () => _openForm(context, PieceFormMode.create),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar peça'),
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
                  Expanded(child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.2))),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: stats
                    .map((s) => Expanded(child: _StatTile(data: s)))
                    .toList(),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(data.value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _kTextDark,
                    letterSpacing: -0.3)),
          ),
        ),
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
// Card de peça
// ─────────────────────────────────────────────────────────────────────────────

class _PieceCard extends StatelessWidget {
  const _PieceCard({
    required this.piece,
    required this.currency,
    required this.onTap,
    required this.onDelete,
    required this.onSale,
  });
  final PieceRecord piece;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSale;

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
                        if (piece.photoName != null)
                          PieceThumb(piece.photoName, width: 48)
                        else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.1),
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
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: <Widget>[
                                  _PriceBadge(
                                    label: 'Custo',
                                    value:
                                        currency.format(piece.productionCost),
                                    color: const Color(0xFF7C3AED),
                                  ),
                                  _PriceBadge(
                                    label: 'Preço',
                                    value: currency
                                        .format(piece.suggestedPrice),
                                    color: const Color(0xFF059669),
                                  ),
                                  if (piece.isSold)
                                    _PriceBadge(
                                      label: 'Vendida por',
                                      value: currency.format(piece.soldPrice),
                                      color: _kPrimary,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(
                                  piece.isSold
                                      ? Icons.undo_rounded
                                      : Icons.sell_outlined,
                                  size: 20),
                              color: const Color(0xFF059669),
                              onPressed: onSale,
                              tooltip: piece.isSold
                                  ? 'Desfazer venda'
                                  : 'Marcar como vendida',
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
// Formulario de registro de peça
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showPieceFormSheet(
  BuildContext context, {
  required List<FabricStock> fabrics,
  required BusinessConfig config,
  required NumberFormat currency,
  required String? Function(CreatePieceInput input) onSave,
  PieceFormMode mode = PieceFormMode.create,
  PieceRecord? initial,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) => _PieceFormSheet(
      fabrics: fabrics,
      config: config,
      currency: currency,
      onSave: onSave,
      mode: mode,
      initial: initial,
    ),
  );
}

class _FabricRow {
  _FabricRow(String id, {String width = '', String length = ''})
      : fabricId = id,
        widthCtrl = TextEditingController(text: width),
        lengthCtrl = TextEditingController(text: length);
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
    required this.mode,
    this.initial,
  });
  final List<FabricStock> fabrics;
  final BusinessConfig config;
  final NumberFormat currency;
  final String? Function(CreatePieceInput) onSave;
  final PieceFormMode mode;

  /// Peça a editar ou duplicar.
  final PieceRecord? initial;

  @override
  State<_PieceFormSheet> createState() => _PieceFormSheetState();
}

class _PieceFormSheetState extends State<_PieceFormSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _extraCtrl =
      TextEditingController(text: '0');
  final TextEditingController _laborCtrl = TextEditingController();
  final TextEditingController _quantityCtrl =
      TextEditingController(text: '1');
  late final List<_FabricRow> _rows;
  String? _photoName;
  String? _error;

  bool get _isQuote => widget.mode == PieceFormMode.quote;
  bool get _isEdit => widget.mode == PieceFormMode.edit;

  @override
  void initState() {
    super.initState();
    _rows = <_FabricRow>[];
    final PieceRecord? initial = widget.initial;
    if (initial != null) {
      _nameCtrl.text = initial.pieceName;
      _extraCtrl.text = formatNumber(initial.additionalMaterialsCost);
      _laborCtrl.text = formatNumber(initial.laborHours);
      _photoName = initial.photoName;
      for (final FabricUsage u in initial.fabricUsages) {
        if (!widget.fabrics.any((FabricStock f) => f.id == u.fabricId)) {
          continue;
        }
        _rows.add(_FabricRow(
          u.fabricId,
          width: formatNumber(u.usedWidthMeters * 100),
          length: formatNumber(u.usedLengthMeters * 100),
        ));
      }
    }
    if (_rows.isEmpty && widget.fabrics.isNotEmpty) {
      _rows.add(_FabricRow(widget.fabrics.first.id));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _extraCtrl.dispose();
    _laborCtrl.dispose();
    for (final _FabricRow r in _rows) { r.dispose(); }
    super.dispose();
  }

  /// Uso do tecido na linha. Ao editar, mantem o preço e a largura que a peça
  /// já tinha para aquele tecido.
  FabricUsage _usageOf(_FabricRow row, FormReader reader) {
    final FabricStock f =
        widget.fabrics.firstWhere((FabricStock x) => x.id == row.fabricId);
    FabricUsage? original;
    if (_isEdit) {
      for (final FabricUsage u in widget.initial!.fabricUsages) {
        if (u.fabricId == f.id) original = u;
      }
    }
    return FabricUsage(
      fabricId: f.id,
      fabricName: f.name,
      fabricWidthMeters: original?.fabricWidthMeters ?? f.widthMeters,
      fabricPricePerMeter: original?.fabricPricePerMeter ?? f.pricePerMeter,
      usedWidthMeters: reader.centimeters('Largura', row.widthCtrl.text),
      usedLengthMeters: reader.centimeters('Comprimento', row.lengthCtrl.text),
    );
  }

  List<FabricUsage> _buildUsages(FormReader reader) =>
      _rows.map((_FabricRow r) => _usageOf(r, reader)).toList();

  CreatePieceInput _readInput(FormReader reader) => CreatePieceInput(
        pieceName: _nameCtrl.text.trim(),
        fabricUsages: _buildUsages(reader),
        additionalMaterialsCost: reader.number(
            'Aviamentos e materiais', _extraCtrl.text,
            thousands: true, emptyAsZero: true),
        laborHours: reader.hours('Tempo gasto (horas)', _laborCtrl.text),
        quantity:
            _isEdit ? 1 : reader.number('Quantidade', _quantityCtrl.text),
        photoName: _photoName,
      );

  Future<void> _shareQuote() async {
    final FormReader reader = FormReader();
    final CreatePieceInput input = _readInput(reader);
    final String? err = reader.error ??
        input.validate(requireMaterials: false) ??
        widget.config.validate();
    setState(() => _error = err);
    if (err != null) return;
    final double materials =
        input.fabricUsages.fold(0, (double s, u) => s + u.fabricCost);
    final PricingBreakdown pricing = calculatePricing(
      config: widget.config,
      laborHours: input.laborHours,
      materialsCost: materials + input.additionalMaterialsCost,
    );
    try {
      await shareText(buildQuoteText(
        pieceName: input.pieceName,
        unitPrice: pricing.suggestedPrice,
        quantity: input.quantity.round(),
        currency: widget.currency,
      ));
    } catch (e) {
      debugPrint('Falha ao compartilhar: $e');
      if (mounted) {
        setState(() => _error = 'Não foi possível abrir o compartilhamento.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<FabricUsage> usages = _buildUsages(FormReader());
    final double quantity = parseDouble(_quantityCtrl.text);
    final double totalFabric =
        usages.fold(0, (double s, FabricUsage u) => s + u.fabricCost);
    final double extra = parseDouble(_extraCtrl.text, thousands: true);
    final double hours = tryParseHours(_laborCtrl.text) ?? 0;
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
                Text(widget.mode.title,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome da peça',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 20),
            PhotoField(
              photoName: _photoName,
              onChanged: (String? v) => setState(() => _photoName = v),
            ),
            const SizedBox(height: 16),
            const _FormSection(label: 'Tecidos utilizados', color: _kPrimary),
            const SizedBox(height: 10),
            ..._rows.asMap().entries.map((MapEntry<int, _FabricRow> e) {
              final int i = e.key;
              final _FabricRow row = e.value;
              final FabricUsage usage = _usageOf(row, FormReader());
              return Container(
                // Sem a chave, remover uma linha trocava o item das outras.
                key: ObjectKey(row),
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
                                          '${f.name} (${formatFixed(f.stockLengthMeters, 2)}m)',
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
                        if (_rows.length > 1 || _isQuote) ...<Widget>[
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
                              labelText: 'Largura (cm)',
                              helperText:
                                  'Máx. ${formatNumber(usage.fabricWidthMeters * 100)} cm',
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
                              labelText: 'Comprimento (cm)',
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
                          'Usa ${formatFixed(usage.equivalentLengthUsedMeters, 2)} m do rolo'
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
              onPressed: widget.fabrics.isEmpty
                  ? null
                  : () => setState(
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
              // O teclado numerico não tem ':' (para digitar 1:30).
              keyboardType: TextInputType.datetime,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Tempo gasto (horas)',
                helperText: 'Ex: 1:30 ou 1.5 = 1h 30min',
                prefixIcon: Icon(Icons.access_time_outlined),
              ),
            ),
            const SizedBox(height: 16),
            _PricingPreviewCard(preview: preview, currency: widget.currency,
                totalFabric: totalFabric, extra: extra),
            if (!_isEdit) ...<Widget>[
              const SizedBox(height: 16),
              TextField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Quantidade de peças iguais',
                  helperText: quantity > 1
                      ? 'Total: ${widget.currency.format(preview.suggestedPrice * quantity)}. '
                          'Medidas e tempo são de UMA peça.'
                      : 'Medidas e tempo são de UMA peça.',
                  helperMaxLines: 2,
                  prefixIcon: const Icon(Icons.copy_all_outlined),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FormError(_error),
            if (_isQuote) ...<Widget>[
              FilledButton.icon(
                onPressed: _shareQuote,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Enviar orçamento'),
              ),
              const SizedBox(height: 10),
            ],
            FilledButton.icon(
              style: _isQuote
                  ? FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF64748B))
                  : null,
              onPressed: () {
                final FormReader reader = FormReader();
                final CreatePieceInput input = _readInput(reader);
                final String? err =
                    reader.error ?? input.validate() ?? widget.onSave(input);
                if (err != null) {
                  setState(() => _error = err);
                  return;
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(_isQuote ? 'Registrar esta peça' : 'Salvar peça'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview de precificação
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
                Text('Quanto cobrar',
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
                _PRow('Seu trabalho',
                    currency.format(preview.laborCost)),
                _PRow('Trabalho + custos fixos',
                    currency.format(preview.operationalCost)),
                _PRow('Custo da peça',
                    currency.format(preview.productionCost),
                    bold: true),
                const Divider(height: 16),
                _PRow('Preço sugerido',
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
// Detalhes da peça
// ─────────────────────────────────────────────────────────────────────────────

void _showPieceDetails(
  BuildContext context,
  PieceRecord piece,
  NumberFormat currency, {
  required VoidCallback onEdit,
  required VoidCallback? onDuplicate,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
            Row(
              children: <Widget>[
                if (!piece.isSold) ...<Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDuplicate == null
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            onDuplicate();
                          },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Duplicar'),
                  ),
                ),
              ],
            ),
            if (piece.photoName != null) ...<Widget>[
              const SizedBox(height: 16),
              PieceThumb(piece.photoName, height: 220),
            ],
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
                        '${formatNumber(u.usedWidthMeters * 100)} × ${formatNumber(u.usedLengthMeters * 100)} cm',
                        style:
                            const TextStyle(fontSize: 12, color: _kTextMid),
                      ),
                      Text(
                        'Usou ${formatFixed(u.equivalentLengthUsedMeters, 2)} m do rolo  ·  Custo: ${currency.format(u.fabricCost)}',
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
                label: 'Como o preço foi calculado', color: _kPrimary),
            const SizedBox(height: 10),
            _PRow('Valor da hora', currency.format(piece.hourlyValue)),
            _PRow(
                'Trabalho (${formatFixed(piece.laborHours, 2)}h)',
                currency.format(piece.laborCost)),
            _PRow('Trabalho + custos fixos',
                currency.format(piece.operationalCost)),
            _PRow('Custo da peça',
                currency.format(piece.productionCost),
                bold: true),
            const Divider(height: 24),
            _PRow('Preço final sugerido',
                currency.format(piece.suggestedPrice),
                bold: true,
                color: const Color(0xFF059669),
                large: true),
            if (piece.isSold) ...<Widget>[
              _PRow('Vendida por', currency.format(piece.soldPrice),
                  bold: true),
              _PRow('Lucro da venda', currency.format(piece.saleProfit),
                  bold: true,
                  color: piece.saleProfit! < 0
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF059669)),
            ],
          ],
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirmar exclusao
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _handleSale(
  BuildContext context,
  PieceRecord piece,
  NumberFormat currency,
  void Function(String id, double? price) onSetSale,
) async {
  if (piece.isSold) {
    if (await confirmUndoSale(context, piece.pieceName)) {
      onSetSale(piece.id, null);
    }
    return;
  }
  final double? price = await promptSalePrice(
    context,
    pieceName: piece.pieceName,
    suggestedPrice: piece.suggestedPrice,
    productionCost: piece.productionCost,
    currency: currency,
  );
  if (price != null) onSetSale(piece.id, price);
}

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
      title: const Text('Excluir peça',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text(
          piece.isSold
          ? 'Deseja excluir "${piece.pieceName}"?\nEla já foi vendida: o material NÃO volta ao estoque e a venda sai dos totais.'
          : 'Deseja excluir "${piece.pieceName}"?\nO consumo dos tecidos será devolvido ao estoque.'),
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
