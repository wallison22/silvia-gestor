import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/utils/id.dart';
import '../models/business_config.dart';
import '../models/create_crochet_piece_input.dart';
import '../models/create_piece_input.dart';
import '../models/crochet_piece_record.dart';
import '../models/fabric_stock.dart';
import '../models/fabric_usage.dart';
import '../models/piece_record.dart';
import '../models/pricing_breakdown.dart';
import '../models/yarn_stock.dart';
import '../models/yarn_usage.dart';
import '../services/local_storage_service.dart';
import '../services/pricing_service.dart';
import 'widgets/crochet_tab.dart';
import 'widgets/fabrics_tab.dart';
import 'widgets/pieces_tab.dart';
import 'widgets/settings_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NumberFormat _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final LocalStorageService _storageService = LocalStorageService();

  bool _loading = true;
  int _tabIndex = 0;

  List<FabricStock> _fabrics = <FabricStock>[];
  List<PieceRecord> _pieces = <PieceRecord>[];
  List<YarnStock> _yarns = <YarnStock>[];
  List<CrochetPieceRecord> _crochetPieces = <CrochetPieceRecord>[];
  BusinessConfig _config = BusinessConfig.defaults();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final LoadedData data = await _storageService.load();
    setState(() {
      _fabrics = data.fabrics;
      _pieces = data.pieces;
      _yarns = data.yarns;
      _crochetPieces = data.crochetPieces;
      _config = data.config;
      _loading = false;
    });
  }

  Future<void> _saveData() {
    return _storageService.save(
      fabrics: _fabrics,
      pieces: _pieces,
      yarns: _yarns,
      crochetPieces: _crochetPieces,
      config: _config,
    );
  }

  // ── Tecidos ───────────────────────────────────────────────────────────────

  void _upsertFabric(FabricStock fabric, {bool mergeIfMatch = false}) {
    setState(() {
      if (mergeIfMatch) {
        final int existingIndex = _fabrics.indexWhere((FabricStock f) {
          return f.name.trim().toLowerCase() ==
                  fabric.name.trim().toLowerCase() &&
              f.storeName.trim().toLowerCase() ==
                  fabric.storeName.trim().toLowerCase() &&
              (f.widthMeters - fabric.widthMeters).abs() < 0.0001 &&
              (f.pricePerMeter - fabric.pricePerMeter).abs() < 0.0001;
        });
        if (existingIndex >= 0) {
          final FabricStock existing = _fabrics[existingIndex];
          _fabrics[existingIndex] = existing.copyWith(
            stockLengthMeters:
                existing.stockLengthMeters + fabric.stockLengthMeters,
          );
        } else {
          _fabrics.add(fabric);
        }
      } else {
        final int index =
            _fabrics.indexWhere((FabricStock f) => f.id == fabric.id);
        if (index >= 0) {
          _fabrics[index] = fabric;
        } else {
          _fabrics.add(fabric);
        }
      }
    });
    _saveData();
  }

  void _deleteFabric(String id) {
    final bool hasUsedPiece = _pieces.any(
      (PieceRecord p) =>
          p.fabricUsages.any((FabricUsage u) => u.fabricId == id),
    );
    if (hasUsedPiece) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao e possivel excluir este tecido pois ele ja foi usado em pecas.',
          ),
        ),
      );
      return;
    }
    setState(() => _fabrics.removeWhere((FabricStock f) => f.id == id));
    _saveData();
  }

  void _addStockToFabric(String fabricId, double extraLengthMeters) {
    setState(() {
      final int index =
          _fabrics.indexWhere((FabricStock f) => f.id == fabricId);
      if (index >= 0) {
        _fabrics[index] = _fabrics[index].copyWith(
          stockLengthMeters:
              _fabrics[index].stockLengthMeters + extraLengthMeters,
        );
      }
    });
    _saveData();
  }

  // ── Pecas de costura ──────────────────────────────────────────────────────

  void _addPiece(CreatePieceInput input) {
    final List<({int index, FabricStock fabric, FabricUsage usage})> resolved =
        <({int index, FabricStock fabric, FabricUsage usage})>[];

    for (final FabricUsage usage in input.fabricUsages) {
      final int idx =
          _fabrics.indexWhere((FabricStock f) => f.id == usage.fabricId);
      if (idx < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Tecido "${usage.fabricName}" nao encontrado no estoque.')),
        );
        return;
      }
      final FabricStock fabric = _fabrics[idx];
      final double needed = usage.equivalentLengthUsedMeters;
      if (needed > fabric.stockLengthMeters + 0.000001) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estoque insuficiente para "${fabric.name}". '
              'Necessario ${needed.toStringAsFixed(2)}m, '
              'disponivel ${fabric.stockLengthMeters.toStringAsFixed(2)}m.',
            ),
          ),
        );
        return;
      }
      resolved.add((index: idx, fabric: fabric, usage: usage));
    }

    final double totalFabricCost = input.fabricUsages
        .fold(0, (double s, FabricUsage u) => s + u.fabricCost);
    final PricingBreakdown pricing = calculatePricing(
      config: _config,
      laborHours: input.laborHours,
      materialsCost: totalFabricCost + input.additionalMaterialsCost,
    );

    final PieceRecord piece = PieceRecord(
      id: newId(),
      pieceName: input.pieceName,
      fabricUsages: input.fabricUsages,
      additionalMaterialsCost: input.additionalMaterialsCost,
      laborHours: input.laborHours,
      hourlyValue: pricing.hourlyValue,
      laborCost: pricing.laborCost,
      operationalCost: pricing.operationalCost,
      productionCost: pricing.productionCost,
      suggestedPrice: pricing.suggestedPrice,
      createdAtIso: DateTime.now().toIso8601String(),
    );

    setState(() {
      _pieces.add(piece);
      for (final r in resolved) {
        _fabrics[r.index] = r.fabric.copyWith(
          stockLengthMeters:
              r.fabric.stockLengthMeters - r.usage.equivalentLengthUsedMeters,
        );
      }
    });
    _saveData();
  }

  void _deletePiece(String pieceId) {
    final int pieceIndex =
        _pieces.indexWhere((PieceRecord p) => p.id == pieceId);
    if (pieceIndex < 0) return;
    final PieceRecord piece = _pieces[pieceIndex];
    setState(() {
      _pieces.removeAt(pieceIndex);
      for (final FabricUsage usage in piece.fabricUsages) {
        final int fabricIndex =
            _fabrics.indexWhere((FabricStock f) => f.id == usage.fabricId);
        if (fabricIndex >= 0) {
          _fabrics[fabricIndex] = _fabrics[fabricIndex].copyWith(
            stockLengthMeters: _fabrics[fabricIndex].stockLengthMeters +
                usage.equivalentLengthUsedMeters,
          );
        }
      }
    });
    _saveData();
  }

  // ── Linhas de croche ──────────────────────────────────────────────────────

  void _addYarn(YarnStock yarn) {
    setState(() => _yarns.add(yarn));
    _saveData();
  }

  void _deleteYarn(String id) {
    setState(() => _yarns.removeWhere((YarnStock y) => y.id == id));
    _saveData();
  }

  void _addStockToYarn(String yarnId, double extraGrams) {
    setState(() {
      final int index =
          _yarns.indexWhere((YarnStock y) => y.id == yarnId);
      if (index >= 0) {
        _yarns[index] = _yarns[index].copyWith(
          stockWeightGrams: _yarns[index].stockWeightGrams + extraGrams,
        );
      }
    });
    _saveData();
  }

  // ── Pecas de croche ───────────────────────────────────────────────────────

  void _addCrochetPiece(CreateCrochetPieceInput input) {
    final List<({int index, YarnStock yarn, YarnUsage usage})> resolved =
        <({int index, YarnStock yarn, YarnUsage usage})>[];

    for (final YarnUsage usage in input.yarnUsages) {
      final int idx =
          _yarns.indexWhere((YarnStock y) => y.id == usage.yarnId);
      if (idx < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Linha "${usage.yarnName}" nao encontrada no estoque.')),
        );
        return;
      }
      final YarnStock yarn = _yarns[idx];
      if (usage.usedWeightGrams > yarn.stockWeightGrams + 0.001) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estoque insuficiente para "${yarn.name}". '
              'Necessario ${usage.usedWeightGrams.toStringAsFixed(1)}g, '
              'disponivel ${yarn.stockWeightGrams.toStringAsFixed(1)}g.',
            ),
          ),
        );
        return;
      }
      resolved.add((index: idx, yarn: yarn, usage: usage));
    }

    final double totalYarnCost =
        input.yarnUsages.fold(0, (double s, YarnUsage u) => s + u.cost);
    final PricingBreakdown pricing = calculatePricing(
      config: _config,
      laborHours: input.laborHours,
      materialsCost: totalYarnCost + input.otherMaterialsCost,
    );

    final CrochetPieceRecord piece = CrochetPieceRecord(
      id: newId(),
      pieceName: input.pieceName,
      yarnUsages: input.yarnUsages,
      otherMaterialsCost: input.otherMaterialsCost,
      laborHours: input.laborHours,
      hourlyValue: pricing.hourlyValue,
      laborCost: pricing.laborCost,
      operationalCost: pricing.operationalCost,
      productionCost: pricing.productionCost,
      suggestedPrice: pricing.suggestedPrice,
      createdAtIso: DateTime.now().toIso8601String(),
    );

    setState(() {
      _crochetPieces.add(piece);
      for (final r in resolved) {
        _yarns[r.index] = r.yarn.copyWith(
          stockWeightGrams:
              r.yarn.stockWeightGrams - r.usage.usedWeightGrams,
        );
      }
    });
    _saveData();
  }

  void _deleteCrochetPiece(String pieceId) {
    final int pieceIndex =
        _crochetPieces.indexWhere((CrochetPieceRecord p) => p.id == pieceId);
    if (pieceIndex < 0) return;
    final CrochetPieceRecord piece = _crochetPieces[pieceIndex];
    setState(() {
      _crochetPieces.removeAt(pieceIndex);
      for (final YarnUsage usage in piece.yarnUsages) {
        final int yarnIndex =
            _yarns.indexWhere((YarnStock y) => y.id == usage.yarnId);
        if (yarnIndex >= 0) {
          _yarns[yarnIndex] = _yarns[yarnIndex].copyWith(
            stockWeightGrams:
                _yarns[yarnIndex].stockWeightGrams + usage.usedWeightGrams,
          );
        }
      }
    });
    _saveData();
  }

  // ── Configuracoes ─────────────────────────────────────────────────────────

  void _saveConfig(BusinessConfig config) {
    setState(() => _config = config);
    _saveData();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando...', style: TextStyle(color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    final Widget body = switch (_tabIndex) {
      0 => FabricsTab(
          fabrics: _fabrics,
          pieceCount: _pieces.length,
          currency: _currency,
          onSaveFabric: _upsertFabric,
          onDeleteFabric: _deleteFabric,
          onAddStock: _addStockToFabric,
        ),
      1 => PiecesTab(
          pieces: _pieces,
          fabrics: _fabrics,
          config: _config,
          currency: _currency,
          onCreatePiece: _addPiece,
          onDeletePiece: _deletePiece,
        ),
      2 => CrochetTab(
          yarns: _yarns,
          crochetPieces: _crochetPieces,
          config: _config,
          currency: _currency,
          onAddYarn: _addYarn,
          onDeleteYarn: _deleteYarn,
          onAddStockToYarn: _addStockToYarn,
          onCreatePiece: _addCrochetPiece,
          onDeletePiece: _deleteCrochetPiece,
        ),
      _ => SettingsTab(
          config: _config,
          currency: _currency,
          onSaveConfig: _saveConfig,
        ),
    };

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB)],
            ),
          ),
        ),
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.content_cut, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SilviaTextil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Gestao de pecas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (int value) =>
              setState(() => _tabIndex = value),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.layers_outlined),
              selectedIcon: Icon(Icons.layers),
              label: 'Tecidos',
            ),
            NavigationDestination(
              icon: Icon(Icons.content_cut_outlined),
              selectedIcon: Icon(Icons.content_cut),
              label: 'Costura',
            ),
            NavigationDestination(
              icon: Icon(Icons.grain_outlined),
              selectedIcon: Icon(Icons.grain),
              label: 'Croche',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Config.',
            ),
          ],
        ),
      ),
    );
  }
}
