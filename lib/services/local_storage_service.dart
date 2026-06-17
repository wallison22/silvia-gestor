import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage_keys.dart';
import '../models/business_config.dart';
import '../models/crochet_piece_record.dart';
import '../models/fabric_stock.dart';
import '../models/piece_record.dart';
import '../models/yarn_stock.dart';

class LoadedData {
  LoadedData({
    required this.fabrics,
    required this.pieces,
    required this.yarns,
    required this.crochetPieces,
    required this.config,
  });

  final List<FabricStock> fabrics;
  final List<PieceRecord> pieces;
  final List<YarnStock> yarns;
  final List<CrochetPieceRecord> crochetPieces;
  final BusinessConfig config;
}

class LocalStorageService {
  Future<LoadedData> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> fabricsRaw =
        prefs.getStringList(StorageKeys.fabrics) ?? <String>[];
    final List<String> piecesRaw =
        prefs.getStringList(StorageKeys.pieces) ?? <String>[];
    final List<String> yarnsRaw =
        prefs.getStringList(StorageKeys.yarns) ?? <String>[];
    final List<String> crochetPiecesRaw =
        prefs.getStringList(StorageKeys.crochetPieces) ?? <String>[];
    final String? configRaw = prefs.getString(StorageKeys.config);

    final List<FabricStock> fabrics = fabricsRaw
        .map((String e) =>
            FabricStock.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    final List<PieceRecord> pieces = piecesRaw
        .map((String e) =>
            PieceRecord.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    final List<YarnStock> yarns = yarnsRaw
        .map((String e) =>
            YarnStock.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    final List<CrochetPieceRecord> crochetPieces = crochetPiecesRaw
        .map((String e) =>
            CrochetPieceRecord.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();

    final BusinessConfig config = configRaw != null
        ? BusinessConfig.fromJson(jsonDecode(configRaw) as Map<String, dynamic>)
        : BusinessConfig.defaults();

    return LoadedData(
      fabrics: fabrics,
      pieces: pieces,
      yarns: yarns,
      crochetPieces: crochetPieces,
      config: config,
    );
  }

  Future<void> save({
    required List<FabricStock> fabrics,
    required List<PieceRecord> pieces,
    required List<YarnStock> yarns,
    required List<CrochetPieceRecord> crochetPieces,
    required BusinessConfig config,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      StorageKeys.fabrics,
      fabrics.map((FabricStock f) => jsonEncode(f.toJson())).toList(),
    );
    await prefs.setStringList(
      StorageKeys.pieces,
      pieces.map((PieceRecord p) => jsonEncode(p.toJson())).toList(),
    );
    await prefs.setStringList(
      StorageKeys.yarns,
      yarns.map((YarnStock y) => jsonEncode(y.toJson())).toList(),
    );
    await prefs.setStringList(
      StorageKeys.crochetPieces,
      crochetPieces
          .map((CrochetPieceRecord p) => jsonEncode(p.toJson()))
          .toList(),
    );
    await prefs.setString(StorageKeys.config, jsonEncode(config.toJson()));
  }
}
