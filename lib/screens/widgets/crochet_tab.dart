import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/id.dart';
import '../../core/utils/parsing.dart';
import '../../models/business_config.dart';
import '../../models/create_crochet_piece_input.dart';
import '../../models/crochet_piece_record.dart';
import '../../models/piece_form_mode.dart';
import '../../models/pricing_breakdown.dart';
import '../../models/yarn_stock.dart';
import '../../models/yarn_usage.dart';
import '../../services/pricing_service.dart';
import '../../services/quote_service.dart';
import 'form_error.dart';
import 'photo_field.dart';
import 'sale_dialog.dart';
import 'search_section.dart';

const Color _kPrimary = Color(0xFF1E40AF);
const Color _kAccent = Color(0xFFF59E0B);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextMid = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kBg = Color(0xFFF8FAFC);

class CrochetTab extends StatefulWidget {
  const CrochetTab({
    required this.yarns,
    required this.crochetPieces,
    required this.config,
    required this.currency,
    required this.onSaveYarn,
    required this.onDeleteYarn,
    required this.onAddStockToYarn,
    required this.onCreatePiece,
    required this.onUpdatePiece,
    required this.onDeletePiece,
    required this.onSetSale,
    super.key,
  });

  final List<YarnStock> yarns;
  final List<CrochetPieceRecord> crochetPieces;
  final BusinessConfig config;
  final NumberFormat currency;
  final void Function(YarnStock yarn) onSaveYarn;
  final void Function(String id) onDeleteYarn;
  final void Function(String yarnId, double extraGrams, double newSkeinPrice)
      onAddStockToYarn;
  final String? Function(CreateCrochetPieceInput input) onCreatePiece;
  final String? Function(String id, CreateCrochetPieceInput input)
      onUpdatePiece;
  final void Function(String id) onDeletePiece;
  final void Function(String id, double? price) onSetSale;

  @override
  State<CrochetTab> createState() => _CrochetTabState();
}

class _CrochetTabState extends State<CrochetTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: _kPrimary,
            unselectedLabelColor: _kTextMid,
            indicatorColor: _kPrimary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const <Tab>[
              Tab(icon: Icon(Icons.grain, size: 18), text: 'Linhas'),
              Tab(icon: Icon(Icons.loop_rounded, size: 18), text: 'Peças'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              _YarnsSubTab(
                yarns: widget.yarns,
                crochetPieces: widget.crochetPieces,
                currency: widget.currency,
                onSaveYarn: widget.onSaveYarn,
                onDeleteYarn: widget.onDeleteYarn,
                onAddStock: widget.onAddStockToYarn,
              ),
              _PiecesSubTab(
                yarns: widget.yarns,
                pieces: widget.crochetPieces,
                config: widget.config,
                currency: widget.currency,
                onCreatePiece: widget.onCreatePiece,
                onUpdatePiece: widget.onUpdatePiece,
                onDeletePiece: widget.onDeletePiece,
                onSetSale: widget.onSetSale,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Componentes de design compartilhados
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
                children:
                    stats
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
// Sub-aba: Linhas
// ─────────────────────────────────────────────────────────────────────────────

class _YarnsSubTab extends StatelessWidget {
  const _YarnsSubTab({
    required this.yarns,
    required this.crochetPieces,
    required this.currency,
    required this.onSaveYarn,
    required this.onDeleteYarn,
    required this.onAddStock,
  });

  final List<YarnStock> yarns;
  final List<CrochetPieceRecord> crochetPieces;
  final NumberFormat currency;
  final void Function(YarnStock) onSaveYarn;
  final void Function(String) onDeleteYarn;
  final void Function(String, double, double) onAddStock;

  @override
  Widget build(BuildContext context) {
    final double totalValue =
        yarns.fold(0, (double s, YarnStock y) => s + y.stockValue);

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            _DashboardCard(
              title: 'Estoque de Linhas',
              icon: Icons.grain_rounded,
              gradient: const <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
              stats: <_StatData>[
                _StatData(
                  icon: Icons.grain_rounded,
                  label: 'Tipos',
                  value: '${yarns.length}',
                  color: _kPrimary,
                ),
                _StatData(
                  icon: Icons.inventory_2_rounded,
                  label: 'Valor estoque',
                  value: currency.format(totalValue),
                  color: const Color(0xFF059669),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (yarns.isEmpty)
              const _EmptyState(
                icon: Icons.grain_outlined,
                title: 'Nenhuma linha cadastrada',
                subtitle: 'Toque em + para adicionar sua primeira linha.',
              )
            else
              SearchSection<YarnStock>(
                  items: yarns,
                  textOf: (YarnStock y) => '${y.name} ${y.storeName}',
                  itemBuilder: (YarnStock yarn) => _YarnCard(
                    yarn: yarn,
                    currency: currency,
                    usedInPieces: crochetPieces.any((CrochetPieceRecord p) =>
                        p.yarnUsages
                            .any((YarnUsage u) => u.yarnId == yarn.id)),
                    onEdit: () => _showYarnFormSheet(context, onSaveYarn,
                        initial: yarn),
                    onAddStock: () =>
                        _showAddStockSheet(context, yarn, onAddStock),
                    onDelete: () =>
                        _confirmDeleteYarn(context, yarn, onDeleteYarn),
                  )),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_yarn',
            onPressed: () => _showYarnFormSheet(context, onSaveYarn),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar linha'),
          ),
        ),
      ],
    );
  }
}

class _YarnCard extends StatelessWidget {
  const _YarnCard({
    required this.yarn,
    required this.currency,
    required this.usedInPieces,
    required this.onEdit,
    required this.onAddStock,
    required this.onDelete,
  });

  final YarnStock yarn;
  final NumberFormat currency;
  final bool usedInPieces;
  final VoidCallback onEdit;
  final VoidCallback onAddStock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool lowStock = yarn.stockWeightGrams < 10;
    final Color accentColor = lowStock ? const Color(0xFFEF4444) : _kPrimary;

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
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
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
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(Icons.grain_rounded,
                          color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(yarn.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: _kTextDark)),
                          if (yarn.storeName.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(yarn.storeName,
                                style: const TextStyle(
                                    fontSize: 12, color: _kTextMid)),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: <Widget>[
                              _Chip(
                                label: 'Estoque',
                                value:
                                    '${formatFixed(yarn.stockWeightGrams, 0)}g',
                                color: accentColor,
                              ),
                              _Chip(
                                label: 'R\$/g',
                                value: yarn.pricePerGram
                                    .toStringAsFixed(4),
                                color: const Color(0xFF7C3AED),
                              ),
                              _Chip(
                                label: 'Valor',
                                value: currency.format(yarn.stockValue),
                                color: const Color(0xFF059669),
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
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: _kPrimary,
                          tooltip: 'Editar linha',
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded,
                              color: _kPrimary.withValues(alpha: 0.8)),
                          tooltip: 'Adicionar estoque',
                          onPressed: onAddStock,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: usedInPieces
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFFFCA5A5),
                            size: 20,
                          ),
                          tooltip: usedInPieces
                              ? 'Usada em peças'
                              : 'Excluir linha',
                          onPressed: usedInPieces ? null : onDelete,
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
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
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
// Sub-aba: Peças de crochê
// ─────────────────────────────────────────────────────────────────────────────

class _PiecesSubTab extends StatelessWidget {
  const _PiecesSubTab({
    required this.yarns,
    required this.pieces,
    required this.config,
    required this.currency,
    required this.onCreatePiece,
    required this.onUpdatePiece,
    required this.onDeletePiece,
    required this.onSetSale,
  });

  final List<YarnStock> yarns;
  final List<CrochetPieceRecord> pieces;
  final BusinessConfig config;
  final NumberFormat currency;
  final String? Function(CreateCrochetPieceInput) onCreatePiece;
  final String? Function(String id, CreateCrochetPieceInput input)
      onUpdatePiece;
  final void Function(String) onDeletePiece;
  final void Function(String id, double? price) onSetSale;

  void _openForm(BuildContext context, PieceFormMode mode,
      [CrochetPieceRecord? piece]) {
    List<YarnStock> available = yarns;
    if (mode == PieceFormMode.edit) {
      // O material da propria peça volta a contar como disponível.
      available = yarns.map((YarnStock s) {
        final double back = piece!.yarnUsages
            .where((u) => u.yarnId == s.id)
            .fold(0, (double t, u) => t + u.usedWeightGrams);
        return s.copyWith(stockWeightGrams: s.stockWeightGrams + back);
      }).toList();
    }
    _showPieceFormSheet(
      context,
      yarns: available,
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
    final double totalRevenue = pieces.fold(
        0, (double s, CrochetPieceRecord p) => s + (p.isSold ? 0 : p.suggestedPrice));
    final double totalSold = pieces.fold(
        0, (double s, CrochetPieceRecord p) => s + (p.soldPrice ?? 0));
    final double totalCost = pieces.fold(
        0, (double s, CrochetPieceRecord p) => s + p.productionCost);

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            _DashboardCard(
              title: 'Peças de Crochê',
              icon: Icons.loop_rounded,
              gradient: const <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
              stats: <_StatData>[
                _StatData(
                  icon: Icons.loop_rounded,
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
                icon: Icons.loop_outlined,
                title: 'Nenhuma peça registrada',
                subtitle: 'Toque em + para registrar sua primeira peça.',
              )
            else
              SearchSection<CrochetPieceRecord>(
                items: pieces.reversed.toList(),
                textOf: (CrochetPieceRecord p) => '${p.pieceName} ${p.yarnsDescription}',
                isSold: (CrochetPieceRecord p) => p.isSold,
                itemBuilder: (CrochetPieceRecord p) => _CrochetPieceCard(
                  piece: p,
                  currency: currency,
                  onTap: () => _showPieceDetails(
                    context,
                    p,
                    currency,
                    onEdit: () => _openForm(context, PieceFormMode.edit, p),
                    onDuplicate: yarns.isEmpty
                        ? null
                        : () =>
                            _openForm(context, PieceFormMode.duplicate, p),
                  ),
                  onDelete: () => _confirmDeletePiece(context, p, onDeletePiece),
                  onSale: () => _handleSale(context, p, currency, onSetSale),
                ),
              ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_crochet_piece',
            onPressed: yarns.isEmpty
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

class _CrochetPieceCard extends StatelessWidget {
  const _CrochetPieceCard({
    required this.piece,
    required this.currency,
    required this.onTap,
    required this.onDelete,
    required this.onSale,
  });

  final CrochetPieceRecord piece;
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
                          child: const Icon(Icons.loop_rounded,
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
                              if (piece.yarnsDescription.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 3),
                                Text(piece.yarnsDescription,
                                    style: const TextStyle(
                                        fontSize: 12, color: _kTextMid),
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
                  fontSize: 12, color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario: Adicionar linha
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _showYarnFormSheet(
  BuildContext context,
  void Function(YarnStock) onSave, {
  YarnStock? initial,
}) async {
  final bool isEdit = initial != null;
  String fmt(double? v) => v == null ? '' : formatNumber(v);

  // Campo não alterado mantem o valor original, sem perder casas decimais.
  double read(FormReader reader, String label, TextEditingController ctrl,
      double? original) {
    if (original != null && ctrl.text == formatNumber(original)) {
      return original;
    }
    return reader.number(label, ctrl.text, thousands: true);
  }

  final TextEditingController nameCtrl =
      TextEditingController(text: initial?.name ?? '');
  final TextEditingController storeCtrl =
      TextEditingController(text: initial?.storeName ?? '');
  final TextEditingController weightCtrl =
      TextEditingController(text: fmt(initial?.skeinWeightGrams));
  final TextEditingController priceCtrl =
      TextEditingController(text: fmt(initial?.skeinPrice));
  final TextEditingController stockCtrl =
      TextEditingController(text: fmt(initial?.stockWeightGrams));
  String? formError;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (BuildContext ctx2, StateSetter setState) {
          final double weight = parseDouble(weightCtrl.text, thousands: true);
          final double price = parseDouble(priceCtrl.text, thousands: true);
          final double pricePerGram = weight > 0 ? price / weight : 0;

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(ctx2).viewInsets.bottom + 24),
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
                        child: const Icon(Icons.grain_rounded,
                            color: _kPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(isEdit ? 'Editar Linha' : 'Cadastrar Linha',
                          style: Theme.of(ctx2).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Nome da linha',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: storeCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Loja / Marca (opcional)',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Peso do novelo (g)',
                            prefixIcon:
                                Icon(Icons.monitor_weight_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Preço pago (R\$)',
                            prefixIcon: Icon(Icons.attach_money_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (pricePerGram > 0) ...<Widget>[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.bolt_rounded,
                              size: 15, color: _kPrimary),
                          const SizedBox(width: 6),
                          Text(
                            'R\$ ${formatFixed(pricePerGram, 4)} por grama',
                            style: const TextStyle(
                                fontSize: 12,
                                color: _kPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: stockCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText:
                          isEdit ? 'Estoque atual (g)' : 'Estoque inicial (g)',
                      helperText: isEdit
                          ? null
                          : 'Deixe em branco para usar o peso do novelo',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                      suffixText: 'g',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FormError(formError),
                  FilledButton.icon(
                    onPressed: () {
                      final FormReader reader = FormReader();
                      final double skeinWeight = read(
                          reader,
                          'Peso do novelo (g)',
                          weightCtrl,
                          initial?.skeinWeightGrams);
                      final double stockGrams =
                          !isEdit && stockCtrl.text.trim().isEmpty
                              ? skeinWeight
                              : read(reader, 'Estoque (g)', stockCtrl,
                                  initial?.stockWeightGrams);

                      final YarnStock yarn = YarnStock(
                        id: initial?.id ?? newId(),
                        name: nameCtrl.text.trim(),
                        storeName: storeCtrl.text.trim(),
                        skeinWeightGrams: skeinWeight,
                        skeinPrice: read(reader, 'Preço pago', priceCtrl,
                            initial?.skeinPrice),
                        stockWeightGrams: stockGrams,
                        createdAtIso: initial?.createdAtIso ??
                            DateTime.now().toIso8601String(),
                      );

                      final String? error = reader.error ?? yarn.validate();
                      if (error != null) {
                        setState(() => formError = error);
                        return;
                      }
                      onSave(yarn);
                      Navigator.pop(ctx2);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label:
                        Text(isEdit ? 'Salvar alterações' : 'Salvar linha'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet: Adicionar estoque a uma linha
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _showAddStockSheet(
  BuildContext context,
  YarnStock yarn,
  void Function(String, double, double) onAddStock,
) async {
  final TextEditingController ctrl = TextEditingController(
      text: formatNumber(yarn.skeinWeightGrams));
  final TextEditingController priceCtrl =
      TextEditingController(text: formatNumber(yarn.skeinPrice));
  String? formError;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setS) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_circle_outline_rounded,
                      color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Adicionar estoque',
                          style: Theme.of(ctx).textTheme.titleMedium),
                      Text(yarn.name,
                          style: const TextStyle(
                              color: _kTextMid, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Gramas a adicionar',
                helperText:
                    'Novelo padrão: ${formatNumber(yarn.skeinWeightGrams)}g',
                prefixIcon: const Icon(Icons.add_circle_outline),
                suffixText: 'g',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText:
                    'Preço do novelo de ${formatNumber(yarn.skeinWeightGrams)}g (R\$)',
                helperText: 'Se mudou, as próximas peças usam o novo preço',
                prefixIcon: const Icon(Icons.attach_money_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FormError(formError),
            FilledButton.icon(
              onPressed: () {
                final FormReader reader = FormReader();
                final double price =
                    priceCtrl.text == formatNumber(yarn.skeinPrice)
                        ? yarn.skeinPrice
                        : reader.number('Preço do novelo', priceCtrl.text,
                            thousands: true);
                if (reader.error != null || price < 0) {
                  setS(() => formError =
                      reader.error ?? 'O preço não pode ser negativo.');
                  return;
                }
                final double extra = parseDouble(ctrl.text, thousands: true);
                if (extra <= 0) {
                  setS(() => formError = 'Informe uma quantidade válida.');
                  return;
                }
                onAddStock(yarn.id, extra, price);
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Adicionar'),
            ),
          ],
        ),
      );
    }),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirmacao: excluir linha
// ─────────────────────────────────────────────────────────────────────────────

void _confirmDeleteYarn(
  BuildContext context,
  YarnStock yarn,
  void Function(String) onDelete,
) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.delete_outline_rounded,
          color: Color(0xFFEF4444), size: 36),
      title: const Text('Excluir linha',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Deseja excluir "${yarn.name}"?'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444)),
          onPressed: () {
            onDelete(yarn.id);
            Navigator.pop(ctx);
          },
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario: Registrar peça de crochê
// ─────────────────────────────────────────────────────────────────────────────

class _YarnRow {
  _YarnRow(String initialYarnId, {String grams = ''})
      : yarnId = initialYarnId,
        gramsController = TextEditingController(text: grams);

  String yarnId;
  final TextEditingController gramsController;

  void dispose() => gramsController.dispose();
}

Future<void> _showPieceFormSheet(
  BuildContext context, {
  required List<YarnStock> yarns,
  required BusinessConfig config,
  required NumberFormat currency,
  required String? Function(CreateCrochetPieceInput input) onSave,
  PieceFormMode mode = PieceFormMode.create,
  CrochetPieceRecord? initial,
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
      yarns: yarns,
      config: config,
      currency: currency,
      onSave: onSave,
      mode: mode,
      initial: initial,
    ),
  );
}

class _PieceFormSheet extends StatefulWidget {
  const _PieceFormSheet({
    required this.yarns,
    required this.config,
    required this.currency,
    required this.onSave,
    required this.mode,
    this.initial,
  });

  final List<YarnStock> yarns;
  final BusinessConfig config;
  final NumberFormat currency;
  final String? Function(CreateCrochetPieceInput) onSave;
  final PieceFormMode mode;

  /// Peça a editar ou duplicar.
  final CrochetPieceRecord? initial;

  @override
  State<_PieceFormSheet> createState() => _PieceFormSheetState();
}

class _PieceFormSheetState extends State<_PieceFormSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _otherCostCtrl =
      TextEditingController(text: '0');
  final TextEditingController _laborCtrl = TextEditingController();
  final TextEditingController _baseMaterialsWeightCtrl =
      TextEditingController();
  final TextEditingController _finishedWeightCtrl = TextEditingController();
  bool _showWeightCalc = false;
  final TextEditingController _quantityCtrl =
      TextEditingController(text: '1');
  late final List<_YarnRow> _rows;
  String? _photoName;
  String? _error;

  bool get _isQuote => widget.mode == PieceFormMode.quote;
  bool get _isEdit => widget.mode == PieceFormMode.edit;

  @override
  void initState() {
    super.initState();
    _rows = <_YarnRow>[];
    final CrochetPieceRecord? initial = widget.initial;
    if (initial != null) {
      _nameCtrl.text = initial.pieceName;
      _otherCostCtrl.text = formatNumber(initial.otherMaterialsCost);
      _laborCtrl.text = formatNumber(initial.laborHours);
      _photoName = initial.photoName;
      for (final YarnUsage u in initial.yarnUsages) {
        if (!widget.yarns.any((YarnStock y) => y.id == u.yarnId)) continue;
        _rows.add(_YarnRow(u.yarnId, grams: formatNumber(u.usedWeightGrams)));
      }
    }
    if (_rows.isEmpty && widget.yarns.isNotEmpty) {
      _rows.add(_YarnRow(widget.yarns.first.id));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _otherCostCtrl.dispose();
    _laborCtrl.dispose();
    _baseMaterialsWeightCtrl.dispose();
    _finishedWeightCtrl.dispose();
    for (final _YarnRow r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  /// Uso da linha. Ao editar, mantem o preço que a peça já tinha para ela.
  YarnUsage _usageOf(_YarnRow row, FormReader reader) {
    final YarnStock yarn =
        widget.yarns.firstWhere((YarnStock y) => y.id == row.yarnId);
    YarnUsage? original;
    if (_isEdit) {
      for (final YarnUsage u in widget.initial!.yarnUsages) {
        if (u.yarnId == yarn.id) original = u;
      }
    }
    return YarnUsage(
      yarnId: yarn.id,
      yarnName: yarn.name,
      yarnPricePerGram: original?.yarnPricePerGram ?? yarn.pricePerGram,
      usedWeightGrams: reader.number(
          'Quantidade usada (g)', row.gramsController.text,
          thousands: true),
    );
  }

  List<YarnUsage> _buildUsages(FormReader reader) =>
      _rows.map((_YarnRow r) => _usageOf(r, reader)).toList();

  CreateCrochetPieceInput _readInput(FormReader reader) =>
      CreateCrochetPieceInput(
        pieceName: _nameCtrl.text.trim(),
        yarnUsages: _buildUsages(reader),
        otherMaterialsCost: reader.number(
            'Custo de outros materiais', _otherCostCtrl.text,
            thousands: true, emptyAsZero: true),
        laborHours: reader.hours('Tempo gasto (horas)', _laborCtrl.text),
        quantity:
            _isEdit ? 1 : reader.number('Quantidade', _quantityCtrl.text),
        photoName: _photoName,
      );

  Future<void> _shareQuote() async {
    final FormReader reader = FormReader();
    final CreateCrochetPieceInput input = _readInput(reader);
    final String? err = reader.error ??
        input.validate(requireMaterials: false) ??
        widget.config.validate();
    setState(() => _error = err);
    if (err != null) return;
    final double materials =
        input.yarnUsages.fold(0, (double s, u) => s + u.cost);
    final PricingBreakdown pricing = calculatePricing(
      config: widget.config,
      laborHours: input.laborHours,
      materialsCost: materials + input.otherMaterialsCost,
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

  void _applyWeightCalc() {
    final double baseWeight = parseDouble(_baseMaterialsWeightCtrl.text,
        thousands: true);
    final double finishedWeight = parseDouble(_finishedWeightCtrl.text,
        thousands: true);
    final double yarnUsed = finishedWeight - baseWeight;
    if (yarnUsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Peso da peça pronta deve ser maior que o peso dos materiais base.')),
      );
      return;
    }
    setState(() {
      _rows.first.gramsController.text = formatNumber(yarnUsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<YarnUsage> usages = _buildUsages(FormReader());
    final double quantity = parseDouble(_quantityCtrl.text);
    final double totalYarnCost =
        usages.fold(0, (double s, YarnUsage u) => s + u.cost);
    final double otherCost =
        parseDouble(_otherCostCtrl.text, thousands: true);
    final double laborHours = tryParseHours(_laborCtrl.text) ?? 0;
    final PricingBreakdown preview = calculatePricing(
      config: widget.config,
      laborHours: laborHours,
      materialsCost: totalYarnCost + otherCost,
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
                  child: const Icon(Icons.loop_rounded,
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
            const _FormSection(label: 'Linhas utilizadas', color: _kPrimary),
            const SizedBox(height: 10),
            ..._rows.asMap().entries.map((MapEntry<int, _YarnRow> entry) {
              final int i = entry.key;
              final _YarnRow row = entry.value;
              final YarnStock yarn = widget.yarns
                  .firstWhere((YarnStock y) => y.id == row.yarnId);
              final YarnUsage usage = _usageOf(row, FormReader());

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
                            initialValue: row.yarnId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Linha',
                              prefixIcon:
                                  const Icon(Icons.grain_rounded),
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
                            items: widget.yarns
                                .map((YarnStock y) =>
                                    DropdownMenuItem<String>(
                                      value: y.id,
                                      child: Text(
                                        '${y.name} (${formatFixed(y.stockWeightGrams, 0)}g)',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() => row.yarnId = value);
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
                    TextField(
                      controller: row.gramsController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Quantidade usada (g)',
                        helperText:
                            'Disponível: ${formatFixed(yarn.stockWeightGrams, 0)}g',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        isDense: true,
                        suffixText: 'g',
                      ),
                    ),
                    if (usage.usedWeightGrams > 0) ...<Widget>[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Custo: ${widget.currency.format(usage.cost)}',
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
              onPressed: widget.yarns.isEmpty
                  ? null
                  : () => setState(
                      () => _rows.add(_YarnRow(widget.yarns.first.id))),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Adicionar outra linha'),
            ),

            // Calculadora de peso
            const SizedBox(height: 4),
            InkWell(
              onTap: () =>
                  setState(() => _showWeightCalc = !_showWeightCalc),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.monitor_weight_outlined,
                        size: 16, color: _kAccent),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Calcular gramas pelo peso da peça',
                        style: TextStyle(
                            fontSize: 13,
                            color: _kAccent,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(
                      _showWeightCalc
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: _kAccent,
                    ),
                  ],
                ),
              ),
            ),

            if (_showWeightCalc) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Pese a peça pronta e informe os pesos abaixo.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _baseMaterialsWeightCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Materiais base (g)',
                              helperText: 'Ex: pano = 72g',
                              suffixText: 'g',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _finishedWeightCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Peça pronta (g)',
                              helperText: 'Peso total',
                              suffixText: 'g',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Builder(builder: (_) {
                      final double base =
                          parseDouble(_baseMaterialsWeightCtrl.text,
        thousands: true);
                      final double finished =
                          parseDouble(_finishedWeightCtrl.text,
        thousands: true);
                      final double yarnUsed = finished - base;
                      return Row(
                        children: <Widget>[
                          if (yarnUsed > 0)
                            Text(
                              'Linha usada: ${formatFixed(yarnUsed, 1)}g',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kAccent,
                              ),
                            ),
                          const Spacer(),
                          OutlinedButton(
                            // O tema usa largura infinita, invalida em Row.
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(88, 44)),
                            onPressed:
                                yarnUsed > 0 && _rows.length == 1
                                    ? _applyWeightCalc
                                    : null,
                            child: const Text('Aplicar'),
                          ),
                        ],
                      );
                    }),
                    if (_rows.length > 1)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Com múltiplas linhas, informe as gramas manualmente.',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF92400E)),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const _FormSection(
                label: 'Outros materiais', color: _kAccent),
            const SizedBox(height: 10),
            TextField(
              controller: _otherCostCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Custo de outros materiais (R\$)',
                helperText: 'Ex: pano de prato, aviamentos',
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
            _PricingPreviewCard(
              preview: preview,
              currency: widget.currency,
              totalYarnCost: totalYarnCost,
              otherCost: otherCost,
            ),
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
                final CreateCrochetPieceInput input = _readInput(reader);
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
    required this.totalYarnCost,
    required this.otherCost,
  });
  final PricingBreakdown preview;
  final NumberFormat currency;
  final double totalYarnCost;
  final double otherCost;

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
                _PRow('Custo de linhas',
                    currency.format(totalYarnCost)),
                _PRow(
                    'Outros materiais', currency.format(otherCost)),
                _PRow('Total materiais',
                    currency.format(totalYarnCost + otherCost),
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

// ─────────────────────────────────────────────────────────────────────────────
// Detalhes da peça de crochê
// ─────────────────────────────────────────────────────────────────────────────

void _showPieceDetails(
  BuildContext context,
  CrochetPieceRecord piece,
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
                  child: const Icon(Icons.loop_rounded, color: _kPrimary),
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
            const _FormSection(label: 'Linhas usadas', color: _kPrimary),
            const SizedBox(height: 10),
            ...piece.yarnUsages.map((YarnUsage u) => Container(
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
                      Text(u.yarnName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _kTextDark)),
                      const SizedBox(height: 4),
                      Text(
                        '${formatFixed(u.usedWeightGrams, 1)}g  x  R\$ ${formatFixed(u.yarnPricePerGram, 4)}/g',
                        style: const TextStyle(
                            fontSize: 12, color: _kTextMid),
                      ),
                      Text(
                        'Custo: ${currency.format(u.cost)}',
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
            _PRow('Custo de linhas', currency.format(piece.totalYarnCost)),
            _PRow('Outros materiais',
                currency.format(piece.otherMaterialsCost)),
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
// Confirmacao: excluir peça
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _handleSale(
  BuildContext context,
  CrochetPieceRecord piece,
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

void _confirmDeletePiece(
  BuildContext context,
  CrochetPieceRecord piece,
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
        'Deseja excluir "${piece.pieceName}"?\n'
        '${piece.isSold ? 'Ela ja foi vendida: o material NAO volta ao estoque e a venda sai dos totais.' : 'O consumo das linhas sera devolvido ao estoque.'}',
      ),
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
