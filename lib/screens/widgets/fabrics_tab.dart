import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/id.dart';
import '../../core/utils/parsing.dart';
import '../../models/fabric_stock.dart';

class FabricsTab extends StatelessWidget {
  const FabricsTab({
    required this.fabrics,
    required this.pieceCount,
    required this.currency,
    required this.onSaveFabric,
    required this.onDeleteFabric,
    required this.onAddStock,
    super.key,
  });

  final List<FabricStock> fabrics;
  final int pieceCount;
  final NumberFormat currency;
  final void Function(FabricStock fabric, {bool mergeIfMatch}) onSaveFabric;
  final void Function(String id) onDeleteFabric;
  final void Function(String id, double extraLengthMeters) onAddStock;

  @override
  Widget build(BuildContext context) {
    final double totalArea = fabrics.fold(
        0, (double s, FabricStock f) => s + f.areaInStockSquareMeters);
    final double totalValue = fabrics.fold(
        0, (double s, FabricStock f) => s + f.stockLengthMeters * f.pricePerMeter);

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            _DashboardCard(
              title: 'Estoque de Tecidos',
              icon: Icons.layers_rounded,
              gradient: const <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
              stats: <_StatData>[
                _StatData(
                  icon: Icons.inventory_2_rounded,
                  label: 'Tecidos',
                  value: '${fabrics.length}',
                  color: const Color(0xFF2563EB),
                ),
                _StatData(
                  icon: Icons.crop_square_rounded,
                  label: 'Area total',
                  value: '${totalArea.toStringAsFixed(1)} m²',
                  color: const Color(0xFF059669),
                ),
                _StatData(
                  icon: Icons.payments_rounded,
                  label: 'Valor est.',
                  value: currency.format(totalValue),
                  color: const Color(0xFFF59E0B),
                ),
                _StatData(
                  icon: Icons.content_cut_rounded,
                  label: 'Pecas',
                  value: '$pieceCount',
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (fabrics.isEmpty)
              const _EmptyState(
                icon: Icons.layers_outlined,
                title: 'Nenhum tecido ainda',
                subtitle: 'Toque em + para cadastrar seu primeiro tecido.',
              )
            else
              ...fabrics.map((FabricStock fabric) => _FabricCard(
                    fabric: fabric,
                    currency: currency,
                    onTap: () => showFabricFormSheet(
                      context,
                      onSaveFabric: onSaveFabric,
                      onDeleteFabric: onDeleteFabric,
                      onAddStock: onAddStock,
                      initial: fabric,
                    ),
                  )),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => showFabricFormSheet(
              context,
              onSaveFabric: onSaveFabric,
              onDeleteFabric: onDeleteFabric,
              onAddStock: onAddStock,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar tecido'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard card com gradiente + tiles de estatisticas
// ─────────────────────────────────────────────────────────────────────────────

class _StatData {
  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
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
            // Cabecalho gradiente
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            // Tiles de estatisticas
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: stats
                    .map((s) => _StatTile(data: s))
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
        Text(
          data.value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          data.label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de tecido
// ─────────────────────────────────────────────────────────────────────────────

class _FabricCard extends StatelessWidget {
  const _FabricCard({
    required this.fabric,
    required this.currency,
    required this.onTap,
  });

  final FabricStock fabric;
  final NumberFormat currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool lowStock = fabric.stockLengthMeters < 1.0;
    const Color primary = Color(0xFF1E40AF);
    final Color accentColor = lowStock ? const Color(0xFFF97316) : primary;
    final double stockValue = fabric.stockLengthMeters * fabric.pricePerMeter;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: <Widget>[
                // Barra lateral colorida
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
                  ),
                ),
                // Conteudo
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(Icons.layers_rounded,
                              color: accentColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      fabric.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (lowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: const Color(0xFFFED7AA)),
                                      ),
                                      child: const Text(
                                        'Estoque baixo',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFC2410C),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (fabric.storeName.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 2),
                                Text(
                                  fabric.storeName,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B)),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: <Widget>[
                                  _Chip(
                                    icon: Icons.straighten_rounded,
                                    text:
                                        '${fabric.widthMeters.toStringAsFixed(2)}m larg.',
                                  ),
                                  _Chip(
                                    icon: Icons.inventory_2_outlined,
                                    text:
                                        '${fabric.stockLengthMeters.toStringAsFixed(2)}m',
                                    highlight: lowStock,
                                  ),
                                  _Chip(
                                    icon: Icons.attach_money_rounded,
                                    text: '${currency.format(fabric.pricePerMeter)}/m',
                                  ),
                                  _Chip(
                                    icon: Icons.wallet_rounded,
                                    text: currency.format(stockValue),
                                    color: const Color(0xFF059669),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFCBD5E1), size: 20),
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.text,
    this.highlight = false,
    this.color,
  });
  final IconData icon;
  final String text;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ??
        (highlight ? const Color(0xFFF97316) : const Color(0xFF64748B));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
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
            child:
                Icon(icon, size: 40, color: const Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario de tecido (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showFabricFormSheet(
  BuildContext context, {
  required void Function(FabricStock fabric, {bool mergeIfMatch}) onSaveFabric,
  required void Function(String id) onDeleteFabric,
  required void Function(String id, double extraLengthMeters) onAddStock,
  FabricStock? initial,
}) async {
  final bool isEdit = initial != null;
  final TextEditingController nameCtrl =
      TextEditingController(text: initial?.name ?? '');
  final TextEditingController storeCtrl =
      TextEditingController(text: initial?.storeName ?? '');
  final TextEditingController widthCtrl = TextEditingController(
      text: initial != null ? initial.widthMeters.toString() : '');
  final TextEditingController stockCtrl = TextEditingController(
      text: initial != null ? initial.stockLengthMeters.toString() : '');
  final TextEditingController priceCtrl = TextEditingController(
      text: initial != null ? initial.pricePerMeter.toString() : '');
  bool mergeIfMatch = true;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (_, void Function(void Function()) setS) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
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
                        child: const Icon(Icons.layers_rounded,
                            color: Color(0xFF1E40AF), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Editar Tecido' : 'Novo Tecido',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome do tecido',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: storeCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Loja / origem (opcional)',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: widthCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Largura (m)',
                            prefixIcon: Icon(Icons.straighten_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Estoque (m)',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Preco por metro linear (R\$)',
                      prefixIcon: Icon(Icons.attach_money_outlined),
                    ),
                  ),
                  if (!isEdit) ...<Widget>[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: mergeIfMatch,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Somar ao estoque se houver tecido igual',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF475569)),
                      ),
                      onChanged: (bool v) => setS(() => mergeIfMatch = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final FabricStock fabric = FabricStock(
                        id: initial?.id ?? newId(),
                        name: nameCtrl.text.trim(),
                        storeName: storeCtrl.text.trim(),
                        widthMeters: parseDouble(widthCtrl.text),
                        stockLengthMeters: parseDouble(stockCtrl.text),
                        pricePerMeter: parseDouble(priceCtrl.text),
                        createdAtIso: initial?.createdAtIso ??
                            DateTime.now().toIso8601String(),
                      );
                      final String? error = fabric.validate();
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)));
                        return;
                      }
                      onSaveFabric(fabric,
                          mergeIfMatch: mergeIfMatch && !isEdit);
                      Navigator.pop(ctx);
                    },
                    child: Text(
                        isEdit ? 'Salvar alteracoes' : 'Salvar tecido'),
                  ),
                  if (isEdit) ...<Widget>[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final double? v = await _promptAddStock(context);
                        if (v != null && v > 0) {
                          onAddStock(initial.id, v);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Adicionar metragem'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                      ),
                      onPressed: () {
                        onDeleteFabric(initial.id);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Excluir tecido'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<double?> _promptAddStock(BuildContext context) async {
  final TextEditingController ctrl = TextEditingController();
  return showDialog<double>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Adicionar metragem'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Metros a adicionar',
          prefixIcon: Icon(Icons.add),
          suffixText: 'm',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final double v = parseDouble(ctrl.text);
            if (v <= 0) return;
            Navigator.pop(ctx, v);
          },
          child: const Text('Adicionar'),
        ),
      ],
    ),
  );
}

// Alias publico para manter compatibilidade
Future<double?> promptAddStock(BuildContext context) => _promptAddStock(context);
