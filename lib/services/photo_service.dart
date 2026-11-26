import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../core/utils/id.dart';

/// Guarda as fotos das peças na pasta privada do app. Os registros salvam só o
/// nome do arquivo.
class PhotoService {
  static Directory? _dir;

  /// Falso quando o aparelho não permite guardar fotos (ex: versão web).
  static bool get available => _dir != null;

  /// Prepara a pasta e apaga as fotos que nenhuma peça usa mais.
  static Future<void> init(Set<String> usedNames) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final Directory docs = await getApplicationSupportDirectory();
      useDirectory(Directory('${docs.path}/fotos'), usedNames);
    } catch (e) {
      debugPrint('Fotos indisponíveis: $e');
    }
  }

  @visibleForTesting
  static void useDirectory(Directory dir, Set<String> usedNames) {
    dir.createSync(recursive: true);
    for (final FileSystemEntity f in dir.listSync()) {
      if (f is File && !usedNames.contains(f.uri.pathSegments.last)) {
        f.deleteSync();
      }
    }
    _dir = dir;
  }

  /// Grava uma foto vinda de um backup.
  static void write(String name, List<int> bytes) {
    final File? f = file(name);
    if (f != null) f.writeAsBytesSync(bytes, flush: true);
  }

  static File? file(String? name) =>
      name == null || _dir == null ? null : File('${_dir!.path}/$name');

  /// Abre a câmera ou a galeria. Retorna o nome da foto salva, ou null se
  /// cancelado.
  static Future<String?> pick({required bool camera}) async {
    final Directory? dir = _dir;
    if (dir == null) return null;
    final XFile? picked = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final String name = '${newId()}.jpg';
    await File(picked.path).copy('${dir.path}/$name');
    return name;
  }
}
