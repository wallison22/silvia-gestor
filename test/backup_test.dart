// Backup: fazer, restaurar, desfazer e arquivos ruins.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silvia_gestor/services/backup_service.dart';
import 'package:silvia_gestor/services/photo_service.dart';

import 'fluxos_app_test.dart' hide main;
import 'novidades_test.dart' show piece;

void main() {
  late Directory tmp;
  late Directory photos;
  File? shared;
  Uint8List? toPick;
  final originals = (shareFile, pickBackupFile, backupDirectory);

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('backup_teste');
    photos = Directory('${tmp.path}/fotos')..createSync();
    File('${photos.path}/a.jpg').writeAsBytesSync(<int>[1, 2, 3]);
    PhotoService.useDirectory(photos, {'a.jpg'});
    shared = null;
    toPick = null;
    backupDirectory = () async => Directory('${tmp.path}/backup')..createSync();
    shareFile = (File f) async {
      shared = f;
      return true;
    };
    pickBackupFile = () async => toPick;
  });
  tearDown(() {
    shareFile = originals.$1;
    pickBackupFile = originals.$2;
    backupDirectory = originals.$3;
    tmp.deleteSync(recursive: true);
  });

  Future<void> openConfig(WidgetTester t) async {
    await tapText(t, 'Config.');
  }

  Future<void> tapButton(WidgetTester t, String text) async {
    await t.runAsync(() async {
      await t.tap(find.text(text).last);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pumpAndSettle();
  }

  Future<String> makeBackup(WidgetTester t) async {
    await openConfig(t);
    await tapButton(t, 'Fazer backup agora');
    return t.runAsync(() => shared!.readAsString()).then((String? s) => s!);
  }

  testWidgets('aviso aparece sem backup e some depois de fazer', (t) async {
    await start(t, fabrics: [fabric()]);
    expect(find.textContaining('ainda não têm backup'), findsOneWidget);
    await makeBackup(t);
    await tapText(t, 'Tecidos');
    expect(find.textContaining('backup'), findsNothing);
    final SharedPreferences p = await SharedPreferences.getInstance();
    expect(p.getString('last_backup'), isNotNull);
    expect(shared!.path, contains('silviatextil-backup-'));
  });

  testWidgets('cancelar o envio não conta como backup feito', (t) async {
    shareFile = (File f) async => false;
    await start(t, fabrics: [fabric()]);
    await openConfig(t);
    await tapButton(t, 'Fazer backup agora');
    expect(find.text('Nenhum backup feito ainda.'), findsOneWidget);
  });

  testWidgets('ida e volta: restaura tudo, inclusive vendas e fotos',
      (t) async {
    await start(t,
        fabrics: [fabric()],
        yarns: [yarn()],
        pieces: [piece(sold: 60, soldAt: '2026-01-05T10:00:00', photo: 'a.jpg')],
        config: <String, dynamic>{
          'desiredMonthlySalary': 3000.0,
          'monthlyWorkHours': 150.0,
          'fixedCostPercent': 20.0,
          'profitPercent': 25.0,
        });
    final String json = await makeBackup(t);
    final Map<String, dynamic> before = <String, dynamic>{
      for (final String k in ['fabrics', 'pieces', 'yarns', 'crochet_pieces'])
        k: await saved(k),
      'config': await savedConfig(),
    };

    // Celular novo: app vazio e sem a foto.
    await t.pumpWidget(const SizedBox());
    File('${photos.path}/a.jpg').deleteSync();
    await start(t);
    toPick = Uint8List.fromList(utf8.encode(json));
    await openConfig(t);
    await tapButton(t, 'Restaurar backup');
    expect(find.textContaining('1 tecido, 1 peça de costura, 1 linha, 0 peças de crochê'),
        findsOneWidget);
    expect(find.textContaining('e 1 foto'), findsOneWidget);
    await tapButton(t, 'Restaurar');
    for (final String k in ['fabrics', 'pieces', 'yarns', 'crochet_pieces']) {
      expect(await saved(k), before[k], reason: k);
    }
    expect(await savedConfig(), before['config']);
    expect(File('${photos.path}/a.jpg').readAsBytesSync(), <int>[1, 2, 3]);
    await tapText(t, 'Costura');
    expect(find.text('Vestido'), findsOneWidget);
    expect(find.text('Vendida por'), findsOneWidget);
  });

  testWidgets('cancelar a confirmação não muda nada', (t) async {
    await start(t, fabrics: [fabric()]);
    final String json = await makeBackup(t);
    await t.pumpWidget(const SizedBox());
    await start(t, yarns: [yarn()]);
    toPick = Uint8List.fromList(utf8.encode(json));
    await openConfig(t);
    await tapButton(t, 'Restaurar backup');
    await tapButton(t, 'Cancelar');
    expect(await saved('fabrics'), isEmpty);
    expect(await saved('yarns'), hasLength(1));
  });

  testWidgets('desfazer volta ao que havia antes de restaurar', (t) async {
    await start(t, fabrics: [fabric()]);
    final String json = await makeBackup(t);
    await t.pumpWidget(const SizedBox());
    await start(t, yarns: [yarn()]);
    toPick = Uint8List.fromList(utf8.encode(json));
    await openConfig(t);
    await tapButton(t, 'Restaurar backup');
    await tapButton(t, 'Restaurar');
    expect(await saved('yarns'), isEmpty);
    expect(await saved('fabrics'), hasLength(1));
    await tapButton(t, 'Desfazer a última restauração');
    expect(await saved('yarns'), hasLength(1));
    expect(await saved('fabrics'), isEmpty);
    expect(find.text('Desfazer a última restauração'), findsNothing);
  });

  for (final MapEntry<String, String> e in <String, String>{
    'texto qualquer': 'não é um backup',
    '{"app":"outro"}': 'não é um backup',
    '{"app":"silviatextil","version":99}': 'versão mais nova',
    '{"app":"silviatextil","version":1,"fabrics":[{"id":1}]}': 'danificado',
    '{"app":"silviatextil","version":1,"createdAtIso":"x","config":'
            '{"desiredMonthlySalary":1,"monthlyWorkHours":1,'
            '"fixedCostPercent":1,"profitPercent":1},"fabrics":[],'
            '"pieces":[],"yarns":[],"crochetPieces":[],'
            '"photos":{"../../prefs.jpg":"AA=="}}':
        'danificado',
  }.entries) {
    testWidgets('arquivo ruim (${e.value}) não apaga nada', (t) async {
      await start(t, fabrics: [fabric()]);
      toPick = Uint8List.fromList(utf8.encode(e.key));
      await openConfig(t);
      await tapButton(t, 'Restaurar backup');
      expect(find.textContaining(e.value), findsOneWidget);
      expect(await saved('fabrics'), hasLength(1));
      expect(Directory(tmp.path).listSync(recursive: true).map((f) => f.path),
          isNot(contains(endsWith('prefs.jpg'))));
    });
  }

  test('nome do arquivo tem a data', () {
    expect(backupFileName(DateTime(2026, 3, 7)),
        'silviatextil-backup-2026-03-07.json');
  });
}
