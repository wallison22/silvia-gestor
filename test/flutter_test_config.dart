import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carrega a Roboto real para que os testes de layout reflitam o celular
/// (a fonte padrao de teste e bem mais larga).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final String root = Platform.environment['FLUTTER_ROOT'] ?? '';
  final FontLoader loader = FontLoader('Roboto');
  for (final String w in <String>['Regular', 'Medium', 'Bold', 'Black']) {
    final File f =
        File('$root/bin/cache/artifacts/material_fonts/Roboto-$w.ttf');
    if (f.existsSync()) {
      loader.addFont(f
          .readAsBytes()
          .then((List<int> b) => ByteData.sublistView(Uint8List.fromList(b))));
    }
  }
  await loader.load();
  await testMain();
}
