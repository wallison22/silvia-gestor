import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/business_config.dart';
import '../models/crochet_piece_record.dart';
import '../models/fabric_stock.dart';
import '../models/piece_record.dart';
import '../models/yarn_stock.dart';
import 'local_storage_service.dart';
import 'photo_service.dart';

const String _kApp = 'silviatextil';
const int _kVersion = 1;
final RegExp _kPhotoName = RegExp(r'^[\w-]+\.jpg$');

/// Abre o compartilhamento com o arquivo. Retorna true se foi enviado (ou se
/// o celular não informa). Trocável em testes.
Future<bool> Function(File file) shareFile = (File file) async {
  final ShareResult r = await SharePlus.instance.share(ShareParams(
    files: <XFile>[XFile(file.path, mimeType: 'application/json')],
    subject: 'Backup SilviaTextil',
  ));
  return r.status != ShareResultStatus.dismissed;
};

/// Abre o seletor de arquivos e devolve o conteúdo, ou null se cancelado.
/// Trocável em testes.
Future<Uint8List?> Function() pickBackupFile = () async {
  final PlatformFile? file = await FilePicker.pickFile();
  return file?.readAsBytes();
};

/// Pasta onde ficam o arquivo a enviar e a cópia de segurança.
/// Trocável em testes.
Future<Directory> Function() backupDirectory = () async =>
    Directory('${(await getApplicationSupportDirectory()).path}/backup')
      ..createSync(recursive: true);

/// Tudo o que o app guarda, inclusive as fotos.
class BackupData {
  BackupData({
    required this.data,
    required this.photos,
    required this.createdAtIso,
  });

  final LoadedData data;

  /// Nome do arquivo -> bytes da foto.
  final Map<String, Uint8List> photos;
  final String createdAtIso;

  int get itemCount =>
      data.fabrics.length +
      data.pieces.length +
      data.yarns.length +
      data.crochetPieces.length;

  String get summary => '${_n(data.fabrics.length, 'tecido', 'tecidos')}, '
      '${_n(data.pieces.length, 'peça de costura', 'peças de costura')}, '
      '${_n(data.yarns.length, 'linha', 'linhas')}, '
      '${_n(data.crochetPieces.length, 'peça de crochê', 'peças de crochê')} '
      'e ${_n(photos.length, 'foto', 'fotos')}';

  static String _n(int n, String one, String many) =>
      '$n ${n == 1 ? one : many}';
}

/// Junta os dados e as fotos de que as peças precisam.
BackupData collectBackup(LoadedData data) {
  final Map<String, Uint8List> photos = <String, Uint8List>{};
  final Iterable<String?> names = <String?>[
    ...data.pieces.map((PieceRecord p) => p.photoName),
    ...data.crochetPieces.map((CrochetPieceRecord p) => p.photoName),
  ];
  for (final String? name in names) {
    final File? f = PhotoService.file(name);
    if (name != null && f != null && f.existsSync()) {
      photos[name] = f.readAsBytesSync();
    }
  }
  return BackupData(
    data: data,
    photos: photos,
    createdAtIso: DateTime.now().toIso8601String(),
  );
}

String encodeBackup(BackupData b) => jsonEncode(<String, dynamic>{
      'app': _kApp,
      'version': _kVersion,
      'createdAtIso': b.createdAtIso,
      'config': b.data.config.toJson(),
      'fabrics': b.data.fabrics.map((FabricStock f) => f.toJson()).toList(),
      'pieces': b.data.pieces.map((PieceRecord p) => p.toJson()).toList(),
      'yarns': b.data.yarns.map((YarnStock y) => y.toJson()).toList(),
      'crochetPieces': b.data.crochetPieces
          .map((CrochetPieceRecord p) => p.toJson())
          .toList(),
      'photos': b.photos
          .map((String k, Uint8List v) => MapEntry(k, base64Encode(v))),
    });

/// Lê um arquivo de backup. Lança [FormatException] com mensagem para a
/// usuária se o arquivo não servir. Nada é gravado aqui.
BackupData decodeBackup(Uint8List bytes) {
  final Map<String, dynamic> j;
  try {
    j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  } catch (_) {
    throw const FormatException('Este arquivo não é um backup do app.');
  }
  if (j['app'] != _kApp) {
    throw const FormatException('Este arquivo não é um backup do app.');
  }
  if ((j['version'] as num? ?? 0) > _kVersion) {
    throw const FormatException(
        'Este backup é de uma versão mais nova do app. Atualize o app antes.');
  }
  try {
    List<Map<String, dynamic>> list(String key) =>
        (j[key] as List<dynamic>).cast<Map<String, dynamic>>();
    final List<FabricStock> fabrics =
        list('fabrics').map(FabricStock.fromJson).toList();
    final Map<String, double> widths = <String, double>{
      for (final FabricStock f in fabrics) f.id: f.widthMeters,
    };
    final Map<String, Uint8List> photos = <String, Uint8List>{};
    (j['photos'] as Map<String, dynamic>? ?? <String, dynamic>{})
        .forEach((String name, dynamic data) {
      // O nome vira caminho de arquivo: só aceita nomes simples.
      if (!_kPhotoName.hasMatch(name)) throw const FormatException('foto');
      photos[name] = base64Decode(data as String);
    });
    return BackupData(
      createdAtIso: j['createdAtIso'] as String,
      photos: photos,
      data: LoadedData(
        fabrics: fabrics,
        pieces: list('pieces')
            .map((Map<String, dynamic> e) =>
                PieceRecord.fromJson(e, fabricWidths: widths))
            .toList(),
        yarns: list('yarns').map(YarnStock.fromJson).toList(),
        crochetPieces:
            list('crochetPieces').map(CrochetPieceRecord.fromJson).toList(),
        config: BusinessConfig.fromJson(j['config'] as Map<String, dynamic>),
      ),
    );
  } catch (e) {
    debugPrint('Backup inválido: $e');
    throw const FormatException('O arquivo de backup está danificado.');
  }
}

/// Nome do arquivo enviado, com a data: silviatextil-backup-2026-11-26.json
String backupFileName(DateTime now) =>
    'silviatextil-backup-${now.year}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}.json';
