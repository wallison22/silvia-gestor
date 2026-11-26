// Editar, duplicar, quantidade, orçamento, resumo, busca, foto e confirmações.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:silvia_gestor/core/utils/parsing.dart';
import 'package:silvia_gestor/models/crochet_piece_record.dart';
import 'package:silvia_gestor/models/piece_record.dart';
import 'package:silvia_gestor/screens/widgets/photo_field.dart';
import 'package:silvia_gestor/screens/widgets/search_section.dart';
import 'package:silvia_gestor/services/photo_service.dart';
import 'package:silvia_gestor/services/quote_service.dart';
import 'package:silvia_gestor/services/summary_service.dart';

import 'fluxos_app_test.dart' hide main;

/// Peça de 150 x 100 cm (1 m do rolo), gravada com preço de R$ 20/m, embora o
/// tecido hoje custe R$ 30/m.
Json piece({
  String id = 'p1',
  String name = 'Vestido',
  double? sold,
  String? soldAt,
  String? photo,
}) =>
    <String, dynamic>{
      'id': id,
      'pieceName': name,
      'fabricUsages': [
        {
          'fabricId': 'f1',
          'fabricName': 'Algodao',
          'fabricWidthMeters': 1.5,
          'fabricPricePerMeter': 20.0,
          'usedWidthMeters': 1.5,
          'usedLengthMeters': 1.0,
        }
      ],
      'additionalMaterialsCost': 0.0,
      'laborHours': 1.0,
      'hourlyValue': 10.0,
      'laborCost': 10.0,
      'operationalCost': 11.0,
      'productionCost': 31.0,
      'suggestedPrice': 50.0,
      'createdAtIso': '2026-01-01T00:00:00',
      'soldPrice': sold,
      'soldAtIso': soldAt,
      'photoName': photo,
    };

Future<void> openDetail(WidgetTester t, [String name = 'Vestido']) async {
  await tapText(t, 'Costura');
  await tapText(t, name);
}

Future<double> stock() async =>
    (await saved('fabrics')).single['stockLengthMeters'] as double;

void main() {
  group('editar', () {
    testWidgets('só o nome não muda preço nem estoque', (t) async {
      await start(t, fabrics: [fabric()], pieces: [piece()]);
      await openDetail(t);
      await tapText(t, 'Editar');
      await type(t, 'Nome da peça', 'Blusa');
      await tapText(t, 'Salvar peça');
      final Json p = (await saved('pieces')).single;
      expect(p, piece(name: 'Blusa'));
      expect(await stock(), 10);
    });

    testWidgets('medida: acerta estoque e mantém o preço antigo do tecido',
        (t) async {
      await start(t, fabrics: [fabric()], pieces: [piece()]);
      await openDetail(t);
      await tapText(t, 'Editar');
      await type(t, 'Comprimento (cm)', '300');
      await tapText(t, 'Salvar peça');
      final Json p = (await saved('pieces')).single;
      expect(p['id'], 'p1');
      // 3 m x R$20 + 1h x 18,1818 x 1,15 = 80,91 / 0,8 = 101,14
      expect(p['productionCost'], 80.91);
      expect(p['suggestedPrice'], 101.14);
      expect(await stock(), closeTo(8, 1e-9));
    });

    testWidgets('material da própria peça conta como disponível', (t) async {
      await start(t, fabrics: [fabric(stock: 0.5)], pieces: [piece()]);
      await openDetail(t);
      await tapText(t, 'Editar');
      await type(t, 'Comprimento (cm)', '151');
      await tapText(t, 'Salvar peça');
      expect(find.textContaining('Estoque insuficiente'), findsOneWidget);
      await type(t, 'Comprimento (cm)', '150');
      await tapText(t, 'Salvar peça');
      expect(await stock(), closeTo(0, 1e-9));
    });

    testWidgets('peça vendida não pode ser editada, mas pode duplicar',
        (t) async {
      await start(t, fabrics: [
        fabric()
      ], pieces: [
        piece(sold: 60, soldAt: '2026-01-05T10:00:00')
      ]);
      await openDetail(t);
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Duplicar'), findsOneWidget);
    });

    testWidgets('crochê: gramas acertam o estoque', (t) async {
      await start(t, yarns: [yarn()]);
      await openCrochet(t);
      await type(t, 'Quantidade usada (g)', '50');
      await type(t, 'Tempo gasto (horas)', '1');
      await tapText(t, 'Salvar peça');
      await tapText(t, 'Tapete');
      await tapText(t, 'Editar');
      await type(t, 'Quantidade usada (g)', '80');
      await tapText(t, 'Salvar peça');
      expect((await saved('yarns')).single['stockWeightGrams'],
          closeTo(20, 1e-9));
      expect(await saved('crochet_pieces'), hasLength(1));
    });
  });

  group('duplicar e quantidade', () {
    testWidgets('duplicar cria 3 à venda, com preço atual e ids únicos',
        (t) async {
      await start(t, fabrics: [
        fabric()
      ], pieces: [
        piece(sold: 60, soldAt: '2026-01-05T10:00:00', photo: 'a.jpg')
      ]);
      await openDetail(t);
      await tapText(t, 'Duplicar');
      await type(t, 'Quantidade de peças iguais', '3');
      await tapText(t, 'Salvar peça');
      final List<Json> ps = await saved('pieces');
      expect(ps, hasLength(4));
      expect(ps.map((p) => p['id']).toSet(), hasLength(4));
      expect(ps.skip(1).every((p) => p['soldPrice'] == null), isTrue);
      expect(ps.skip(1).every((p) => p['photoName'] == 'a.jpg'), isTrue);
      // 1 m x R$30 + 20,91 = 50,91 / 0,8 = 63,64
      expect(ps[1]['suggestedPrice'], 63.64);
      expect(await stock(), closeTo(7, 1e-9));
    });

    testWidgets('quantidade multiplica o estoque necessário', (t) async {
      await start(t, fabrics: [fabric(stock: 2.5)]);
      await openPiece(t);
      await fillPiece(t);
      await type(t, 'Largura (cm)', '150');
      await type(t, 'Quantidade de peças iguais', '3');
      await tapText(t, 'Salvar peça');
      expect(await saved('pieces'), isEmpty);
      expect(find.textContaining('Estoque insuficiente'), findsOneWidget);
    });

    for (final String q in ['', '0', '-1', '1,5', '101', 'abc']) {
      testWidgets('quantidade "$q" recusada', (t) async {
        await start(t, fabrics: [fabric(stock: 5000)]);
        await openPiece(t);
        await fillPiece(t);
        await type(t, 'Quantidade de peças iguais', q);
        await tapText(t, 'Salvar peça');
        expect(await saved('pieces'), isEmpty);
      });
    }
  });

  testWidgets('remover a 1ª linha não troca o tecido da 2ª', (t) async {
    final Json seda = fabric(price: 100)
      ..['id'] = 'f2'
      ..['name'] = 'Seda';
    await start(t, fabrics: [fabric(), seda]);
    await openPiece(t);
    await tapText(t, 'Adicionar outro tecido');
    await t.tap(find.byType(DropdownButtonFormField<String>).last);
    await t.pumpAndSettle();
    await tapText(t, 'Seda (10,00m)');
    await t.tap(find.byIcon(Icons.remove_circle_outline).first);
    await t.pumpAndSettle();
    expect(find.text('Seda (10,00m)'), findsWidgets);
    expect(
        t
            .state<FormFieldState<String>>(
                find.byType(DropdownButtonFormField<String>))
            .value,
        'f2');
  });

  group('orçamento', () {
    final Future<void> Function(String) original = shareText;
    tearDown(() => shareText = original);

    testWidgets('sem estoque nenhum: calcula, envia e não grava', (t) async {
      String? sent;
      shareText = (String s) async => sent = s;
      await start(t);
      await tapText(t, 'Costura');
      await tapText(t, 'Fazer orçamento');
      await type(t, 'Nome da peça', 'Cortina');
      await type(t, 'Aviamentos e materiais (R\$)', '75');
      await type(t, 'Tempo gasto (horas)', '3');
      await type(t, 'Quantidade de peças iguais', '2');
      await tapText(t, 'Enviar orçamento');
      expect(sent, contains('Cortina'));
      expect(sent, contains('172,16'));
      expect(sent, contains('344,32'));
      expect(sent, isNot(contains('137,73')), reason: 'não vaza o custo');
      expect(await saved('pieces'), isEmpty);
    });

    testWidgets('ignora falta de estoque; registrar respeita', (t) async {
      String? sent;
      shareText = (String s) async => sent = s;
      await start(t, fabrics: [fabric(stock: 0)]);
      await tapText(t, 'Costura');
      await tapText(t, 'Fazer orçamento');
      await type(t, 'Nome da peça', 'Saia');
      await fillPiece(t);
      await tapText(t, 'Enviar orçamento');
      expect(sent, isNotNull);
      await tapText(t, 'Registrar esta peça');
      expect(await saved('pieces'), isEmpty);
      expect(find.textContaining('Estoque insuficiente'), findsOneWidget);
    });

    testWidgets('tempo em branco não envia', (t) async {
      String? sent;
      shareText = (String s) async => sent = s;
      await start(t);
      await tapText(t, 'Costura');
      await tapText(t, 'Fazer orçamento');
      await type(t, 'Nome da peça', 'Saia');
      await tapText(t, 'Enviar orçamento');
      expect(sent, isNull);
    });

    test('texto com uma peça', () {
      expect(
          buildQuoteText(
              pieceName: 'Saia',
              unitPrice: 10,
              quantity: 1,
              currency: NumberFormat.simpleCurrency(locale: 'pt_BR')),
          isNot(contains('Total')));
    });
  });

  group('resumo', () {
    test('filtra pelo mês da venda e soma certo', () {
      PieceRecord p(Json j) => PieceRecord.fromJson(j);
      final MonthSummary s = summarizeMonth(
        pieces: [
          p(piece(id: '1', sold: 50, soldAt: '2026-03-31T23:59:00')),
          p(piece(id: '2', name: 'vestido ', sold: 20, soldAt: '2026-03-01T00:00:00')),
          p(piece(id: '3', sold: 99, soldAt: '2026-04-01T00:00:00')),
          p(piece(id: '4', sold: 99, soldAt: '2025-03-10T00:00:00')),
          p(piece(id: '5')),
        ],
        crochetPieces: [
          CrochetPieceRecord(
            id: 'c',
            pieceName: 'Tapete',
            yarnUsages: const [],
            otherMaterialsCost: 0,
            laborHours: 2,
            hourlyValue: 10,
            laborCost: 20,
            operationalCost: 20,
            productionCost: 20,
            suggestedPrice: 30,
            createdAtIso: '',
            soldPrice: 45,
            soldAtIso: '2026-03-15T12:00:00',
          ),
        ],
        year: 2026,
        month: 3,
      );
      expect(s.sales, hasLength(3));
      expect(s.revenue, 115);
      expect(s.cost, 82);
      expect(s.profit, 33);
      expect(s.laborCost, 40);
      expect(s.laborHours, 4);
      expect(s.products.map((p) => p.name), ['Tapete', 'Vestido']);
      expect(s.products.last.count, 2);
      expect(s.products.last.profit, 8);
      expect(s.sales.first.date.day, 31);
    });

    testWidgets('tela: mês atual, mês anterior e trava no futuro', (t) async {
      await start(t, fabrics: [
        fabric()
      ], pieces: [
        piece(sold: 60, soldAt: DateTime.now().toIso8601String())
      ]);
      await tapText(t, 'Resumo');
      expect(find.text('Total vendido'), findsOneWidget);
      expect(find.textContaining('29,00'), findsNWidgets(2));
      expect(
          t
              .widget<IconButton>(find.ancestor(
                  of: find.byIcon(Icons.chevron_right_rounded),
                  matching: find.byType(IconButton)))
              .onPressed,
          isNull);
      await t.tap(find.byTooltip('Mês anterior'));
      await t.pumpAndSettle();
      expect(find.textContaining('Nenhuma venda'), findsOneWidget);
    });
  });

  group('busca e filtro', () {
    test('ignora acento, maiúscula e ordem', () {
      expect(matchesSearch('lencol', 'Lençol de Berço'), isTrue);
      expect(matchesSearch('BERÇO lenç', 'lencol de berco'), isTrue);
      expect(matchesSearch('', 'x'), isTrue);
      expect(matchesSearch('saia', 'Lençol'), isFalse);
    });

    testWidgets('filtra vendidas e busca pelo tecido', (t) async {
      await start(t, fabrics: [
        fabric()
      ], pieces: [
        piece(id: '1', name: 'Saia'),
        piece(id: '2', name: 'Blusa', sold: 60, soldAt: '2026-01-05T10:00:00'),
      ]);
      await tapText(t, 'Costura');
      await tapText(t, 'Vendidas');
      expect(find.text('Saia'), findsNothing);
      expect(find.text('Blusa'), findsOneWidget);
      await tapText(t, 'À venda');
      expect(find.text('Saia'), findsOneWidget);
      expect(find.text('Blusa'), findsNothing);
      await tapText(t, 'Todas');
      await t.enterText(find.widgetWithText(TextField, 'Buscar'), 'ALGODÃO');
      await t.pump();
      expect(find.text('Saia'), findsOneWidget);
      await t.enterText(find.widgetWithText(TextField, 'ALGODÃO'), 'zzz');
      await t.pump();
      expect(find.text('Nada encontrado.'), findsOneWidget);
    });

    testWidgets('excluir com filtro ativo apaga a peça certa', (t) async {
      await start(t, fabrics: [
        fabric()
      ], pieces: [
        piece(id: '1', name: 'Saia'),
        piece(id: '2', name: 'Blusa'),
      ]);
      await tapText(t, 'Costura');
      await t.enterText(find.widgetWithText(TextField, 'Buscar'), 'saia');
      await t.pump();
      await deletePiece(t);
      expect((await saved('pieces')).single['id'], '2');
    });
  });

  group('foto', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('fotos_teste'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('apaga só as fotos sem uso', () {
      File('${dir.path}/usada.jpg').writeAsStringSync('x');
      File('${dir.path}/solta.jpg').writeAsStringSync('x');
      PhotoService.useDirectory(dir, {'usada.jpg'});
      expect(PhotoService.file('usada.jpg')!.existsSync(), isTrue);
      expect(PhotoService.file('solta.jpg')!.existsSync(), isFalse);
    });

    testWidgets('foto perdida não quebra a tela; formulário mostra botões',
        (t) async {
      PhotoService.useDirectory(dir, {});
      await start(t, fabrics: [fabric()], pieces: [piece(photo: 'sumiu.jpg')]);
      await openDetail(t);
      expect(find.byType(PieceThumb), findsWidgets);
      await tapText(t, 'Editar');
      expect(find.text('Tirar foto'), findsOneWidget);
      await tapText(t, 'Remover foto');
      await tapText(t, 'Salvar peça');
      final Json p = (await saved('pieces')).single;
      expect(p['photoName'], isNull);
      expect(p['suggestedPrice'], 50.0);
      expect(t.takeException(), isNull);
    });
  });

  group('centímetros', () {
    test('ida e volta sem perder precisão', () {
      for (int cm = 1; cm <= 1000; cm++) {
        final FormReader r = FormReader();
        final double m = r.centimeters('x', '$cm');
        expect(formatNumber(m * 100), '$cm');
        expect(r.error, isNull);
      }
      expect(FormReader().centimeters('x', '1.500'), 15);
      expect(FormReader().centimeters('x', '70,5'), closeTo(.705, 1e-12));
    });

    for (final MapEntry<String, double?> e in <String, double?>{
      '140': 1.4,
      '1,40': null,
      '': null,
    }.entries) {
      testWidgets('largura do rolo "${e.key}"', (t) async {
        await start(t);
        await tapText(t, 'Adicionar tecido');
        await type(t, 'Nome do tecido', 'Linho');
        await type(t, 'Largura (cm)', e.key);
        await type(t, 'Estoque (metros)', '2,5');
        await type(t, 'Preço por metro linear (R\$)', '10');
        await tapText(t, 'Salvar tecido');
        final List<Json> f = await saved('fabrics');
        expect(f.isEmpty ? null : f.single['widthMeters'], e.value);
      });
    }

    testWidgets('largura acima do rolo é recusada', (t) async {
      await start(t, fabrics: [fabric()]);
      await openPiece(t);
      await fillPiece(t);
      await type(t, 'Largura (cm)', '151');
      await tapText(t, 'Salvar peça');
      expect(await saved('pieces'), isEmpty);
      expect(find.textContaining('150 cm'), findsWidgets);
    });
  });

  testWidgets('excluir tecido pede confirmação', (t) async {
    await start(t, fabrics: [fabric()]);
    await tapText(t, 'Algodao');
    await tapText(t, 'Excluir tecido');
    await tapText(t, 'Cancelar');
    expect(await saved('fabrics'), hasLength(1));
    await tapText(t, 'Excluir tecido');
    await tapText(t, 'Excluir');
    expect(await saved('fabrics'), isEmpty);
  });

  for (final double w in [320.0, 412.0]) {
    for (final double scale in [1.0, 1.5]) {
      testWidgets('telas novas cabem em ${w}px com fonte ${scale}x', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await start(t, size: Size(w, 4000), fabrics: [
          fabric()
        ], pieces: [
          piece(sold: 123456.78, soldAt: DateTime.now().toIso8601String()),
        ]);
        await tapText(t, 'Resumo');
        expect(t.takeException(), isNull);
        await openDetail(t);
        expect(t.takeException(), isNull);
        await tapText(t, 'Duplicar');
        expect(t.takeException(), isNull);
      });
    }
  }
}
