// Simula o uso real: abre o app, digita nos formularios, salva e confere o
// que foi gravado no armazenamento local.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silvia_gestor/app.dart';

typedef Json = Map<String, dynamic>;

Json fabric({double stock = 10, double price = 30}) => <String, dynamic>{
      'id': 'f1',
      'name': 'Algodao',
      'storeName': '',
      'widthMeters': 1.5,
      'stockLengthMeters': stock,
      'pricePerMeter': price,
      'createdAtIso': '2026-01-01T00:00:00',
    };

Json yarn({double stock = 100, double skein = 200}) => <String, dynamic>{
      'id': 'y1',
      'name': 'Barroco',
      'storeName': '',
      'skeinWeightGrams': skein,
      'skeinPrice': 20.0,
      'stockWeightGrams': stock,
      'createdAtIso': '2026-01-01T00:00:00',
    };

Future<void> start(WidgetTester t,
    {List<Json> fabrics = const <Json>[],
    List<Json> yarns = const <Json>[],
    List<Json> pieces = const <Json>[],
    Json? config,
    Size size = const Size(412, 3000)}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues(<String, Object>{
    'fabrics': fabrics.map(jsonEncode).toList(),
    'yarns': yarns.map(jsonEncode).toList(),
    'pieces': pieces.map(jsonEncode).toList(),
    if (config != null) 'config': jsonEncode(config),
  });
  await t.pumpWidget(const SewingStoreApp());
  await t.pumpAndSettle();
}

Future<List<Json>> saved(String key) async {
  final SharedPreferences p = await SharedPreferences.getInstance();
  return (p.getStringList(key) ?? <String>[])
      .map((String e) => jsonDecode(e) as Json)
      .toList();
}

Future<Json> savedConfig() async {
  final SharedPreferences p = await SharedPreferences.getInstance();
  final String? c = p.getString('config');
  return c == null ? <String, dynamic>{} : jsonDecode(c) as Json;
}

Finder field(String label) => find.widgetWithText(TextField, label);

Future<void> type(WidgetTester t, String label, String v, {int at = 0}) async {
  await t.enterText(field(label).at(at), v);
  await t.pump();
}

Future<void> tapText(WidgetTester t, String s) async {
  await t.tap(find.text(s).last);
  await t.pumpAndSettle();
}

Future<void> openPiece(WidgetTester t) async {
  await tapText(t, 'Costura');
  await tapText(t, 'Registrar peça');
  await type(t, 'Nome da peça', 'Vestido');
}

Future<void> fillPiece(WidgetTester t, {String hours = '1'}) async {
  await type(t, 'Largura (cm)', '100');
  await type(t, 'Comprimento (cm)', '100');
  await type(t, 'Tempo gasto (horas)', hours);
}

Future<void> openCrochet(WidgetTester t) async {
  await tapText(t, 'Crochê');
  await t.tap(find.descendant(
      of: find.byType(TabBar), matching: find.textContaining('eças')));
  await t.pumpAndSettle();
  await t.tap(find.byType(FloatingActionButton).last);
  await t.pumpAndSettle();
  await type(t, 'Nome da peça', 'Tapete');
}

Future<void> deletePiece(WidgetTester t) async {
  await t.tap(find.byTooltip('Excluir'));
  await t.pumpAndSettle();
  await tapText(t, 'Excluir');
}

void main() {
  group('costura', () {
    testWidgets('peça normal: preço e baixa de estoque', (t) async {
      await start(t, fabrics: [fabric()]);
      await openPiece(t);
      await type(t, 'Largura (cm)', '75');
      await type(t, 'Comprimento (cm)', '200');
      await type(t, 'Aviamentos e materiais (R\$)', '10,50');
      await type(t, 'Tempo gasto (horas)', '2,5');
      await tapText(t, 'Salvar peça');
      final Json p = (await saved('pieces')).single;
      // tecido 30 + 10,50; trabalho 2,5 * 18,1818 * 1,15 = 52,2727
      expect(p['productionCost'], closeTo(92.77, .006));
      expect(p['suggestedPrice'], closeTo(115.97, .006));
      expect((await saved('fabrics')).single['stockLengthMeters'],
          closeTo(9, 1e-9));
    });

    testWidgets('preço gravado tem no maximo 2 casas', (t) async {
      await start(t, fabrics: [fabric()]);
      await openPiece(t);
      await type(t, 'Largura (cm)', '33');
      await type(t, 'Comprimento (cm)', '77');
      await type(t, 'Tempo gasto (horas)', '1');
      await tapText(t, 'Salvar peça');
      final double v = (await saved('pieces')).single['suggestedPrice'];
      expect(v, double.parse(v.toStringAsFixed(2)));
    });

    testWidgets('mesmo tecido em 2 linhas: baixa a soma e devolve igual',
        (t) async {
      await start(t, fabrics: [fabric()]);
      await openPiece(t);
      await tapText(t, 'Adicionar outro tecido');
      for (int i = 0; i < 2; i++) {
        await type(t, 'Largura (cm)', '150', at: i);
        await type(t, 'Comprimento (cm)', '${(i + 2) * 100}', at: i);
      }
      await type(t, 'Tempo gasto (horas)', '1');
      await tapText(t, 'Salvar peça');
      expect((await saved('fabrics')).single['stockLengthMeters'],
          closeTo(5, 1e-9));
      await deletePiece(t);
      expect((await saved('fabrics')).single['stockLengthMeters'],
          closeTo(10, 1e-9));
    });

    testWidgets('mesmo tecido em 2 linhas não passa do estoque', (t) async {
      await start(t, fabrics: [fabric(stock: 3)]);
      await openPiece(t);
      await tapText(t, 'Adicionar outro tecido');
      for (int i = 0; i < 2; i++) {
        await type(t, 'Largura (cm)', '150', at: i);
        await type(t, 'Comprimento (cm)', '200', at: i);
      }
      await type(t, 'Tempo gasto (horas)', '1');
      await tapText(t, 'Salvar peça');
      expect(await saved('pieces'), isEmpty);
      expect((await saved('fabrics')).single['stockLengthMeters'], 3);
    });

    testWidgets('estoque insuficiente mantem o formulario e mostra o erro',
        (t) async {
      await start(t, fabrics: [fabric(stock: 0.1)]);
      await openPiece(t);
      await fillPiece(t);
      await tapText(t, 'Salvar peça');
      expect(await saved('pieces'), isEmpty);
      expect(
          find.descendant(
              of: find.byType(BottomSheet),
              matching: find.textContaining('Estoque insuficiente')),
          findsOneWidget);
    });

    testWidgets('erro de validacao aparece dentro do formulario', (t) async {
      await start(t, fabrics: [fabric()]);
      await openPiece(t);
      await fillPiece(t);
      await type(t, 'Nome da peça', '');
      await tapText(t, 'Salvar peça');
      expect(
          find.descendant(
              of: find.byType(BottomSheet),
              matching: find.textContaining('Informe o nome')),
          findsOneWidget);
    });

    for (final String h in ['', 'abc', '1h3x', '-1', 'NaN', 'Infinity']) {
      testWidgets('tempo "$h" não grava peça', (t) async {
        await start(t, fabrics: [fabric()]);
        await openPiece(t);
        await fillPiece(t, hours: h);
        await tapText(t, 'Salvar peça');
        expect(await saved('pieces'), isEmpty);
        expect(find.text('Salvar peça'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }

    for (final MapEntry<String, double> e in <String, double>{
      '1:30': 1.5,
      '1h30': 1.5,
      '0': 0,
      '2': 2,
      '1,25': 1.25,
    }.entries) {
      testWidgets('tempo "${e.key}" = ${e.value}h', (t) async {
        await start(t, fabrics: [fabric()]);
        await openPiece(t);
        await fillPiece(t, hours: e.key);
        await tapText(t, 'Salvar peça');
        expect((await saved('pieces')).single['laborHours'], e.value);
      });
    }

    for (final MapEntry<String, double> e in <String, double>{
      '1.234,56': 1234.56,
      'R\$ 12,50': 12.5,
      '1.200': 1200,
      '12.50': 12.5,
      '': 0,
    }.entries) {
      testWidgets('aviamento "${e.key}" = ${e.value}', (t) async {
        await start(t, fabrics: [fabric()]);
        await openPiece(t);
        await fillPiece(t);
        await type(t, 'Aviamentos e materiais (R\$)', e.key);
        await tapText(t, 'Salvar peça');
        expect(
            (await saved('pieces')).single['additionalMaterialsCost'], e.value);
      });
    }

    testWidgets('consumir tudo nunca deixa estoque negativo', (t) async {
      await start(t, fabrics: [fabric(stock: 0.9999995)]);
      await openPiece(t);
      await fillPiece(t);
      await type(t, 'Largura (cm)', '150');
      await tapText(t, 'Salvar peça');
      expect((await saved('fabrics')).single['stockLengthMeters'], 0);
    });

    testWidgets('registro antigo devolve metros lineares, não área', (t) async {
      await start(t, fabrics: [
        fabric(stock: 5)
      ], pieces: [
        <String, dynamic>{
          'id': 'p',
          'pieceName': 'Antiga',
          'fabricId': 'f1',
          'fabricName': 'Algodao',
          'fabricCost': 30.0,
          'usedWidthMeters': 0.75,
          'usedLengthMeters': 2.0,
          'additionalMaterialsCost': 0,
          'laborHours': 1,
          'hourlyValue': 1,
          'laborCost': 1,
          'operationalCost': 1,
          'productionCost': 31,
          'suggestedPrice': 40,
          'createdAtIso': ''
        }
      ]);
      await tapText(t, 'Costura');
      await deletePiece(t);
      expect((await saved('fabrics')).single['stockLengthMeters'],
          closeTo(6, 1e-9));
    });
  });

  group('tecido', () {
    Future<void> novo(WidgetTester t, String price) async {
      await start(t);
      await tapText(t, 'Adicionar tecido');
      await type(t, 'Nome do tecido', 'Linho');
      await type(t, 'Largura (cm)', '140');
      await type(t, 'Estoque (metros)', '2,5');
      await type(t, 'Preço por metro linear (R\$)', price);
      await tapText(t, 'Salvar tecido');
    }

    for (final String v in ['', 'abc', '-5', 'Infinity', '1,2,3']) {
      testWidgets('preço "$v" e recusado', (t) async {
        await novo(t, v);
        expect(await saved('fabrics'), isEmpty);
        expect(find.text('Salvar tecido'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('preço 1.250,90', (t) async {
      await novo(t, '1.250,90');
      expect((await saved('fabrics')).single['pricePerMeter'], 1250.90);
    });

    testWidgets('editar so o nome preserva os numeros', (t) async {
      await start(t,
          fabrics: [fabric(stock: 9.533333333333333, price: 39.125)]);
      await tapText(t, 'Algodao');
      await type(t, 'Nome do tecido', 'Novo');
      await tapText(t, 'Salvar alterações');
      final Json f = (await saved('fabrics')).single;
      expect(f['name'], 'Novo');
      expect(f['stockLengthMeters'], 9.533333333333333);
      expect(f['pricePerMeter'], 39.125);
    });
  });

  group('crochê', () {
    testWidgets('preço e estoque com a mesma linha duas vezes', (t) async {
      await start(t, yarns: [yarn()]);
      await openCrochet(t);
      await tapText(t, 'Adicionar outra linha');
      await type(t, 'Quantidade usada (g)', '30', at: 0);
      await type(t, 'Quantidade usada (g)', '20', at: 1);
      await type(t, 'Tempo gasto (horas)', '2');
      await tapText(t, 'Salvar peça');
      // linha 5,00 + 2 * 18,1818 * 1,15 = 46,8182 / 0,8 = 58,52
      expect((await saved('crochet_pieces')).single['suggestedPrice'],
          closeTo(58.52, .006));
      expect(
          (await saved('yarns')).single['stockWeightGrams'], closeTo(50, 1e-9));
      await deletePiece(t);
      expect((await saved('yarns')).single['stockWeightGrams'],
          closeTo(100, 1e-9));
    });

    testWidgets('soma acima do estoque e recusada', (t) async {
      await start(t, yarns: [yarn()]);
      await openCrochet(t);
      await tapText(t, 'Adicionar outra linha');
      await type(t, 'Quantidade usada (g)', '60', at: 0);
      await type(t, 'Quantidade usada (g)', '60', at: 1);
      await type(t, 'Tempo gasto (horas)', '2');
      await tapText(t, 'Salvar peça');
      expect(await saved('crochet_pieces'), isEmpty);
      expect(find.text('Salvar peça'), findsOneWidget);
    });

    testWidgets('tempo em branco e recusado', (t) async {
      await start(t, yarns: [yarn()]);
      await openCrochet(t);
      await type(t, 'Quantidade usada (g)', '10');
      await tapText(t, 'Salvar peça');
      expect(await saved('crochet_pieces'), isEmpty);
    });

    testWidgets('calculadora de peso aplica a diferenca', (t) async {
      await start(t, yarns: [yarn()]);
      await openCrochet(t);
      await tapText(t, 'Calcular gramas pelo peso da peça');
      await type(t, 'Materiais base (g)', '72');
      await type(t, 'Peça pronta (g)', '100,5');
      await tapText(t, 'Aplicar');
      await type(t, 'Tempo gasto (horas)', '1');
      await tapText(t, 'Salvar peça');
      expect((await saved('yarns')).single['stockWeightGrams'],
          closeTo(71.5, 1e-9));
    });

    testWidgets('novelo sem preço e recusado', (t) async {
      await start(t);
      await tapText(t, 'Crochê');
      await t.tap(find.byType(FloatingActionButton).first);
      await t.pumpAndSettle();
      await type(t, 'Nome da linha', 'X');
      await type(t, 'Peso do novelo (g)', '100');
      await tapText(t, 'Salvar linha');
      expect(await saved('yarns'), isEmpty);
    });

    testWidgets('cone de 1.200 g vale 1200 g', (t) async {
      await start(t);
      await tapText(t, 'Crochê');
      await t.tap(find.byType(FloatingActionButton).first);
      await t.pumpAndSettle();
      await type(t, 'Nome da linha', 'X');
      await type(t, 'Peso do novelo (g)', '1.200');
      await type(t, 'Preço pago (R\$)', '60');
      await tapText(t, 'Salvar linha');
      expect((await saved('yarns')).single['skeinWeightGrams'], 1200);
    });

    testWidgets('adicionar estoque sugere o peso exato do novelo', (t) async {
      await start(t, yarns: [yarn(skein: 12.5)]);
      await tapText(t, 'Crochê');
      await t.tap(find.byTooltip('Adicionar estoque'));
      await t.pumpAndSettle();
      await tapText(t, 'Adicionar');
      expect((await saved('yarns')).single['stockWeightGrams'], 112.5);
    });
  });

  group('config', () {
    Future<void> set(WidgetTester t, String label, String v) async {
      await start(t);
      await tapText(t, 'Config.');
      await type(t, label, v);
      await tapText(t, 'Salvar configurações');
    }

    for (final String bad in ['', '0', '-10', 'abc', '800']) {
      testWidgets('horas "$bad" recusadas', (t) async {
        await set(t, 'Horas de trabalho por mês', bad);
        expect(await savedConfig(), isEmpty);
      });
    }
    for (final String bad in ['', '100', '150', '-5']) {
      testWidgets('lucro "$bad" recusado', (t) async {
        await set(t, 'Lucro (%)', bad);
        expect(await savedConfig(), isEmpty);
      });
    }
    for (final String bad in ['', '-1']) {
      testWidgets('custos fixos "$bad" recusados', (t) async {
        await set(t, 'Custos fixos (%)', bad);
        expect(await savedConfig(), isEmpty);
      });
    }
    for (final String v in ['4.000', '4.000,00', 'R\$ 4000', '4000']) {
      testWidgets('salário "$v" = 4000', (t) async {
        await set(t, 'Salário mensal desejado (R\$)', v);
        expect((await savedConfig())['desiredMonthlySalary'], 4000);
      });
    }

    testWidgets('simulação acompanha o que esta digitado', (t) async {
      await start(t);
      await tapText(t, 'Config.');
      await type(t, 'Lucro (%)', '50');
      // (3 * 18,1818 * 1,15 + 75) / 0,5 = 275,45
      expect(find.textContaining('275,4'), findsOneWidget);
    });

    testWidgets('config invalida já gravada não gera preço absurdo', (t) async {
      await start(t, fabrics: [
        fabric()
      ], config: <String, dynamic>{
        'desiredMonthlySalary': 4000,
        'monthlyWorkHours': 0,
        'fixedCostPercent': 15,
        'profitPercent': 100
      });
      await openPiece(t);
      await fillPiece(t);
      await tapText(t, 'Salvar peça');
      expect(await saved('pieces'), isEmpty);
    });
  });

  testWidgets('registro corrompido não trava o app no carregamento', (t) async {
    t.view.physicalSize = const Size(412, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'fabrics': <String>['{quebrado']
    });
    await t.pumpWidget(const SewingStoreApp());
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
    expect(find.textContaining('Não foi possível carregar'), findsOneWidget);
    // Os dados originais nao podem ser sobrescritos.
    final SharedPreferences p = await SharedPreferences.getInstance();
    expect(p.getStringList('fabrics'), <String>['{quebrado']);
  });

  for (final double w in [320.0, 360.0, 412.0]) {
    testWidgets('sem estouro de layout em ${w}px com valores altos', (t) async {
      await start(t,
          size: Size(w, 800),
          fabrics: [fabric(stock: 4000, price: 99.9)],
          yarns: [yarn(stock: 900000)]);
      expect(t.takeException(), isNull);
      for (final String tab in ['Costura', 'Crochê', 'Config.']) {
        await tapText(t, tab);
        expect(t.takeException(), isNull, reason: tab);
      }
    });
  }
}
