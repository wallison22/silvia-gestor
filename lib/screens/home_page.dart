import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/utils/id.dart';
import '../core/utils/parsing.dart';
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
import '../services/backup_service.dart';
import '../services/local_storage_service.dart';
import '../services/photo_service.dart';
import '../services/pricing_service.dart';
import 'widgets/crochet_tab.dart';
import 'widgets/fabrics_tab.dart';
import 'widgets/pieces_tab.dart';
import 'widgets/settings_tab.dart';
import 'widgets/summary_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NumberFormat _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final LocalStorageService _storageService = LocalStorageService();

  bool _loading = true;
  bool _loadFailed = false;
  DateTime? _lastBackup;
  bool _hasSafetyCopy = false;
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
    final LoadedData data;
    try {
      data = await _storageService.load();
    } catch (e) {
      // Não segue com listas vazias: o proximo salvamento apagaria os dados.
      debugPrint('Falha ao carregar dados: $e');
      if (mounted) setState(() => _loadFailed = true);
      return;
    }
    // Não bloqueia a abertura do app; as fotos aparecem quando prontas.
    _initPhotos(data);
    _loadBackupInfo();
    if (!mounted) return;
    setState(() {
      _fabrics = data.fabrics;
      _pieces = data.pieces;
      _yarns = data.yarns;
      _crochetPieces = data.crochetPieces;
      _config = data.config;
      _loading = false;
    });
  }

  void _initPhotos(LoadedData data) {
    PhotoService.init(<String>{
      for (final PieceRecord p in data.pieces)
        if (p.photoName != null) p.photoName!,
      for (final CrochetPieceRecord p in data.crochetPieces)
        if (p.photoName != null) p.photoName!,
    }).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ── Backup ────────────────────────────────────────────────────────────────

  LoadedData get _currentData => LoadedData(
        fabrics: _fabrics,
        pieces: _pieces,
        yarns: _yarns,
        crochetPieces: _crochetPieces,
        config: _config,
      );

  Future<File> _safetyFile() async =>
      File('${(await backupDirectory()).path}/antes-de-restaurar.json');

  Future<void> _loadBackupInfo() async {
    try {
      final DateTime? last = await _storageService.lastBackup();
      final bool safety = (await _safetyFile()).existsSync();
      if (mounted) {
        setState(() {
          _lastBackup = last;
          _hasSafetyCopy = safety;
        });
      }
    } catch (e) {
      debugPrint('Backup indisponível: $e');
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? const Color(0xFFB91C1C) : null,
    ));
  }

  Future<void> _exportBackup() async {
    try {
      final DateTime now = DateTime.now();
      final File file =
          File('${(await backupDirectory()).path}/${backupFileName(now)}');
      await file.writeAsString(encodeBackup(collectBackup(_currentData)),
          flush: true);
      if (!await shareFile(file)) return;
      await _storageService.setLastBackup(now);
      if (mounted) setState(() => _lastBackup = now);
    } catch (e) {
      debugPrint('Falha no backup: $e');
      if (mounted) _message('Não foi possível criar o backup.', error: true);
    }
  }

  Future<void> _importBackup() async {
    final BackupData backup;
    try {
      final List<int>? bytes = await pickBackupFile();
      if (bytes == null) return;
      backup = decodeBackup(Uint8List.fromList(bytes));
    } on FormatException catch (e) {
      if (mounted) _message(e.message, error: true);
      return;
    } catch (e) {
      debugPrint('Falha ao abrir backup: $e');
      if (mounted) _message('Não foi possível abrir o arquivo.', error: true);
      return;
    }
    if (!mounted) return;
    final DateTime? date = DateTime.tryParse(backup.createdAtIso);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Restaurar backup'),
        content: Text(
          'Backup${date == null ? '' : ' de ${_date(date)}'} com '
          '${backup.summary}.\n\n'
          'Isso vai SUBSTITUIR tudo o que está no app agora. '
          'Uma cópia do que existe hoje fica guardada para desfazer.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final String? error = await _restore(backup, keepSafetyCopy: true);
    if (!mounted) return;
    _message(error ?? 'Backup restaurado.', error: error != null);
  }

  Future<void> _undoRestore() async {
    try {
      final File file = await _safetyFile();
      final BackupData backup = decodeBackup(await file.readAsBytes());
      final String? error = await _restore(backup, keepSafetyCopy: false);
      if (error == null) await file.delete();
      if (!mounted) return;
      setState(() => _hasSafetyCopy = error != null);
      _message(error ?? 'Restauração desfeita.', error: error != null);
    } catch (e) {
      debugPrint('Falha ao desfazer: $e');
      if (mounted) _message('Não foi possível desfazer.', error: true);
    }
  }

  /// Troca todos os dados pelos do backup.
  Future<String?> _restore(BackupData backup,
      {required bool keepSafetyCopy}) async {
    try {
      if (keepSafetyCopy) {
        // Guarda o que existe hoje antes de qualquer gravação.
        await (await _safetyFile()).writeAsString(
            encodeBackup(collectBackup(_currentData)),
            flush: true);
      }
      backup.photos.forEach(PhotoService.write);
      final LoadedData d = backup.data;
      await _storageService.save(
        fabrics: d.fabrics,
        pieces: d.pieces,
        yarns: d.yarns,
        crochetPieces: d.crochetPieces,
        config: d.config,
      );
      if (!mounted) return null;
      setState(() {
        _fabrics = d.fabrics;
        _pieces = d.pieces;
        _yarns = d.yarns;
        _crochetPieces = d.crochetPieces;
        _config = d.config;
        if (keepSafetyCopy) _hasSafetyCopy = true;
      });
      _initPhotos(d);
      return null;
    } catch (e) {
      debugPrint('Falha ao restaurar: $e');
      return 'Não foi possível restaurar o backup.';
    }
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  bool get _backupOverdue {
    final bool hasData = _fabrics.isNotEmpty ||
        _yarns.isNotEmpty ||
        _pieces.isNotEmpty ||
        _crochetPieces.isNotEmpty;
    final DateTime? last = _lastBackup;
    return hasData &&
        (last == null || DateTime.now().difference(last).inDays >= 30);
  }

  Future<void> _saveData() async {
    try {
      await _storageService.save(
        fabrics: _fabrics,
        pieces: _pieces,
        yarns: _yarns,
        crochetPieces: _crochetPieces,
        config: _config,
      );
    } catch (e) {
      debugPrint('Falha ao salvar dados: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Atenção: não foi possível salvar os dados.')),
      );
    }
  }

  /// Subtrai do estoque sem deixar residuo negativo de arredondamento.
  static double _subtract(double stock, double used) {
    final double left = stock - used;
    return left < 0.000001 ? 0 : left;
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
            'Não é possível excluir este tecido pois ele já foi usado em peças.',
          ),
        ),
      );
      return;
    }
    setState(() => _fabrics.removeWhere((FabricStock f) => f.id == id));
    _saveData();
  }

  void _addStockToFabric(
      String fabricId, double extraLengthMeters, double newPricePerMeter) {
    setState(() {
      final int index =
          _fabrics.indexWhere((FabricStock f) => f.id == fabricId);
      if (index >= 0) {
        _fabrics[index] = _fabrics[index].copyWith(
          stockLengthMeters:
              _fabrics[index].stockLengthMeters + extraLengthMeters,
          pricePerMeter: newPricePerMeter,
        );
      }
    });
    _saveData();
  }

  // ── Peças de costura ──────────────────────────────────────────────────────

  /// Soma por item: o mesmo pode aparecer em varias linhas da peça.
  static Map<String, double> _neededFabrics(List<FabricUsage> usages, [int times = 1]) {
    final Map<String, double> needed = <String, double>{};
    for (final FabricUsage u in usages) {
      needed[u.fabricId] = (needed[u.fabricId] ?? 0) + u.equivalentLengthUsedMeters * times;
    }
    return needed;
  }

  /// Retorna o erro se faltar estoque. [credit] e o que será devolvido antes.
  String? _checkFabrics(Map<String, double> needed, Map<String, double> credit) {
    for (final MapEntry<String, double> e in needed.entries) {
      final int idx = _fabrics.indexWhere((FabricStock s) => s.id == e.key);
      if (idx < 0) return 'Tecido não encontrado no estoque.';
      final double available = _fabrics[idx].stockLengthMeters + (credit[e.key] ?? 0);
      if (e.value > available + 0.000001) {
        return 'Estoque insuficiente para "${_fabrics[idx].name}". '
            'Necessário ${formatFixed(e.value, 2)} m, '
            'disponível ${formatFixed(available, 2)} m.';
      }
    }
    return null;
  }

  void _consumeFabrics(Map<String, double> needed, Map<String, double> credit) {
    for (int i = 0; i < _fabrics.length; i++) {
      final double? used = needed[_fabrics[i].id];
      final double? back = credit[_fabrics[i].id];
      if (used == null && back == null) continue;
      _fabrics[i] = _fabrics[i].copyWith(
        stockLengthMeters:
            _subtract(_fabrics[i].stockLengthMeters + (back ?? 0), used ?? 0),
      );
    }
  }

  PieceRecord _buildPieceRecord(CreatePieceInput input, String id, String createdAtIso) {
    final double materials = input.fabricUsages
        .fold(0, (double s, FabricUsage u) => s + u.fabricCost);
    final PricingBreakdown pricing = calculatePricing(
      config: _config,
      laborHours: input.laborHours,
      materialsCost: materials + input.additionalMaterialsCost,
    );
    return PieceRecord(
      id: id,
      pieceName: input.pieceName,
      fabricUsages: input.fabricUsages,
      additionalMaterialsCost: input.additionalMaterialsCost,
      laborHours: input.laborHours,
      hourlyValue: pricing.hourlyValue,
      laborCost: pricing.laborCost,
      operationalCost: pricing.operationalCost,
      productionCost: pricing.productionCost,
      suggestedPrice: pricing.suggestedPrice,
      createdAtIso: createdAtIso,
      photoName: input.photoName,
    );
  }

  /// Registra uma ou mais peças iguais. Retorna o erro, ou null se deu certo.
  String? _addPiece(CreatePieceInput input) {
    final String? configError = _config.validate();
    if (configError != null) return 'Corrija a aba Config.: $configError';

    final int quantity = input.quantity.round();
    final Map<String, double> needed =
        _neededFabrics(input.fabricUsages, quantity);
    final String? stockError = _checkFabrics(needed, const <String, double>{});
    if (stockError != null) return stockError;

    final String baseId = newId();
    final String now = DateTime.now().toIso8601String();
    setState(() {
      for (int i = 0; i < quantity; i++) {
        final String id = quantity == 1 ? baseId : '$baseId-$i';
        _pieces.add(_buildPieceRecord(input, id, now));
      }
      _consumeFabrics(needed, const <String, double>{});
    });
    _saveData();
    return null;
  }

  /// Corrige uma peça ainda não vendida. O preço so e recalculado se algo que
  /// entra no custo mudou.
  String? _updatePiece(String id, CreatePieceInput input) {
    final int index = _pieces.indexWhere((PieceRecord p) => p.id == id);
    if (index < 0) return 'Peça não encontrada.';
    final PieceRecord old = _pieces[index];
    if (old.isSold) return 'Desfaça a venda antes de editar a peça.';

    bool sameUsage(FabricUsage a, FabricUsage b) =>
        a.fabricId == b.fabricId &&
          (a.usedWidthMeters - b.usedWidthMeters).abs() < 1e-5 &&
          (a.usedLengthMeters - b.usedLengthMeters).abs() < 1e-5;
    bool sameCost =
        (old.laborHours - input.laborHours).abs() < 1e-5 &&
            (old.additionalMaterialsCost - input.additionalMaterialsCost).abs() < 1e-5 &&
            old.fabricUsages.length == input.fabricUsages.length;
    for (int i = 0; sameCost && i < old.fabricUsages.length; i++) {
      sameCost = sameUsage(old.fabricUsages[i], input.fabricUsages[i]);
    }
    if (sameCost) {
      setState(() {
        _pieces[index] = old.withDetails(input.pieceName, input.photoName);
      });
      _saveData();
      return null;
    }

    final String? configError = _config.validate();
    if (configError != null) return 'Corrija a aba Config.: $configError';
    final Map<String, double> credit = _neededFabrics(old.fabricUsages);
    final Map<String, double> needed = _neededFabrics(input.fabricUsages);
    final String? stockError = _checkFabrics(needed, credit);
    if (stockError != null) return stockError;
    setState(() {
      _pieces[index] =
          _buildPieceRecord(input, old.id, old.createdAtIso);
      _consumeFabrics(needed, credit);
    });
    _saveData();
    return null;
  }

  /// Registra a venda, ou a desfaz se [price] for null.
  void _setPieceSale(String id, double? price) {
    setState(() {
      final int i = _pieces.indexWhere((PieceRecord p) => p.id == id);
      if (i >= 0) {
        _pieces[i] = _pieces[i].withSale(
            price, price == null ? null : DateTime.now().toIso8601String());
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
      // Peça vendida saiu com o material: nada volta ao estoque.
      if (piece.isSold) return;
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

  // ── Linhas de crochê ──────────────────────────────────────────────────────

  void _upsertYarn(YarnStock yarn) {
    setState(() {
      final int i = _yarns.indexWhere((YarnStock y) => y.id == yarn.id);
      if (i >= 0) {
        _yarns[i] = yarn;
      } else {
        _yarns.add(yarn);
      }
    });
    _saveData();
  }

  void _deleteYarn(String id) {
    setState(() => _yarns.removeWhere((YarnStock y) => y.id == id));
    _saveData();
  }

  void _addStockToYarn(
      String yarnId, double extraGrams, double newSkeinPrice) {
    setState(() {
      final int index =
          _yarns.indexWhere((YarnStock y) => y.id == yarnId);
      if (index >= 0) {
        _yarns[index] = _yarns[index].copyWith(
          stockWeightGrams: _yarns[index].stockWeightGrams + extraGrams,
          skeinPrice: newSkeinPrice,
        );
      }
    });
    _saveData();
  }

  // ── Peças de crochê ───────────────────────────────────────────────────────

  /// Soma por item: o mesmo pode aparecer em varias linhas da peça.
  static Map<String, double> _neededYarns(List<YarnUsage> usages, [int times = 1]) {
    final Map<String, double> needed = <String, double>{};
    for (final YarnUsage u in usages) {
      needed[u.yarnId] = (needed[u.yarnId] ?? 0) + u.usedWeightGrams * times;
    }
    return needed;
  }

  /// Retorna o erro se faltar estoque. [credit] e o que será devolvido antes.
  String? _checkYarns(Map<String, double> needed, Map<String, double> credit) {
    for (final MapEntry<String, double> e in needed.entries) {
      final int idx = _yarns.indexWhere((YarnStock s) => s.id == e.key);
      if (idx < 0) return 'Linha não encontrada no estoque.';
      final double available = _yarns[idx].stockWeightGrams + (credit[e.key] ?? 0);
      if (e.value > available + 0.000001) {
        return 'Estoque insuficiente para "${_yarns[idx].name}". '
            'Necessário ${formatFixed(e.value, 1)} g, '
            'disponível ${formatFixed(available, 1)} g.';
      }
    }
    return null;
  }

  void _consumeYarns(Map<String, double> needed, Map<String, double> credit) {
    for (int i = 0; i < _yarns.length; i++) {
      final double? used = needed[_yarns[i].id];
      final double? back = credit[_yarns[i].id];
      if (used == null && back == null) continue;
      _yarns[i] = _yarns[i].copyWith(
        stockWeightGrams:
            _subtract(_yarns[i].stockWeightGrams + (back ?? 0), used ?? 0),
      );
    }
  }

  CrochetPieceRecord _buildCrochetPieceRecord(CreateCrochetPieceInput input, String id, String createdAtIso) {
    final double materials = input.yarnUsages
        .fold(0, (double s, YarnUsage u) => s + u.cost);
    final PricingBreakdown pricing = calculatePricing(
      config: _config,
      laborHours: input.laborHours,
      materialsCost: materials + input.otherMaterialsCost,
    );
    return CrochetPieceRecord(
      id: id,
      pieceName: input.pieceName,
      yarnUsages: input.yarnUsages,
      otherMaterialsCost: input.otherMaterialsCost,
      laborHours: input.laborHours,
      hourlyValue: pricing.hourlyValue,
      laborCost: pricing.laborCost,
      operationalCost: pricing.operationalCost,
      productionCost: pricing.productionCost,
      suggestedPrice: pricing.suggestedPrice,
      createdAtIso: createdAtIso,
      photoName: input.photoName,
    );
  }

  /// Registra uma ou mais peças iguais. Retorna o erro, ou null se deu certo.
  String? _addCrochetPiece(CreateCrochetPieceInput input) {
    final String? configError = _config.validate();
    if (configError != null) return 'Corrija a aba Config.: $configError';

    final int quantity = input.quantity.round();
    final Map<String, double> needed =
        _neededYarns(input.yarnUsages, quantity);
    final String? stockError = _checkYarns(needed, const <String, double>{});
    if (stockError != null) return stockError;

    final String baseId = newId();
    final String now = DateTime.now().toIso8601String();
    setState(() {
      for (int i = 0; i < quantity; i++) {
        final String id = quantity == 1 ? baseId : '$baseId-$i';
        _crochetPieces.add(_buildCrochetPieceRecord(input, id, now));
      }
      _consumeYarns(needed, const <String, double>{});
    });
    _saveData();
    return null;
  }

  /// Corrige uma peça ainda não vendida. O preço so e recalculado se algo que
  /// entra no custo mudou.
  String? _updateCrochetPiece(String id, CreateCrochetPieceInput input) {
    final int index = _crochetPieces.indexWhere((CrochetPieceRecord p) => p.id == id);
    if (index < 0) return 'Peça não encontrada.';
    final CrochetPieceRecord old = _crochetPieces[index];
    if (old.isSold) return 'Desfaça a venda antes de editar a peça.';

    bool sameUsage(YarnUsage a, YarnUsage b) =>
        a.yarnId == b.yarnId &&
          (a.usedWeightGrams - b.usedWeightGrams).abs() < 1e-5;
    bool sameCost =
        (old.laborHours - input.laborHours).abs() < 1e-5 &&
            (old.otherMaterialsCost - input.otherMaterialsCost).abs() < 1e-5 &&
            old.yarnUsages.length == input.yarnUsages.length;
    for (int i = 0; sameCost && i < old.yarnUsages.length; i++) {
      sameCost = sameUsage(old.yarnUsages[i], input.yarnUsages[i]);
    }
    if (sameCost) {
      setState(() {
        _crochetPieces[index] = old.withDetails(input.pieceName, input.photoName);
      });
      _saveData();
      return null;
    }

    final String? configError = _config.validate();
    if (configError != null) return 'Corrija a aba Config.: $configError';
    final Map<String, double> credit = _neededYarns(old.yarnUsages);
    final Map<String, double> needed = _neededYarns(input.yarnUsages);
    final String? stockError = _checkYarns(needed, credit);
    if (stockError != null) return stockError;
    setState(() {
      _crochetPieces[index] =
          _buildCrochetPieceRecord(input, old.id, old.createdAtIso);
      _consumeYarns(needed, credit);
    });
    _saveData();
    return null;
  }

  /// Registra a venda, ou a desfaz se [price] for null.
  void _setCrochetSale(String id, double? price) {
    setState(() {
      final int i = _crochetPieces.indexWhere((CrochetPieceRecord p) => p.id == id);
      if (i >= 0) {
        _crochetPieces[i] = _crochetPieces[i].withSale(
            price, price == null ? null : DateTime.now().toIso8601String());
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
      // Peça vendida saiu com o material: nada volta ao estoque.
      if (piece.isSold) return;
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

  // ── Configurações ─────────────────────────────────────────────────────────

  void _saveConfig(BusinessConfig config) {
    setState(() => _config = config);
    _saveData();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Não foi possível carregar os dados salvos.\n'
              'Nada foi apagado. Não desinstale o app e peça ajuda.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
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
          onUpdatePiece: _updatePiece,
          onDeletePiece: _deletePiece,
          onSetSale: _setPieceSale,
        ),
      2 => CrochetTab(
          yarns: _yarns,
          crochetPieces: _crochetPieces,
          config: _config,
          currency: _currency,
          onSaveYarn: _upsertYarn,
          onDeleteYarn: _deleteYarn,
          onAddStockToYarn: _addStockToYarn,
          onCreatePiece: _addCrochetPiece,
          onUpdatePiece: _updateCrochetPiece,
          onDeletePiece: _deleteCrochetPiece,
          onSetSale: _setCrochetSale,
        ),
      3 => SummaryTab(
          pieces: _pieces,
          crochetPieces: _crochetPieces,
          currency: _currency,
        ),
      _ => SettingsTab(
          config: _config,
          currency: _currency,
          onSaveConfig: _saveConfig,
          lastBackup: _lastBackup,
          hasSafetyCopy: _hasSafetyCopy,
          onExportBackup: _exportBackup,
          onImportBackup: _importBackup,
          onUndoRestore: _undoRestore,
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
            const Expanded(child: Column(
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
                  'Gestão de peças',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          if (_backupOverdue && _tabIndex != 4)
            Material(
              color: const Color(0xFFFFF7ED),
              child: InkWell(
                onTap: () => setState(() => _tabIndex = 4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.backup_outlined,
                          color: Color(0xFFC2410C), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _lastBackup == null
                              ? 'Seus dados ainda não têm backup. Toque aqui.'
                              : 'Último backup há mais de 30 dias. Toque aqui.',
                          style: const TextStyle(
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
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
              label: 'Crochê',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Resumo',
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
