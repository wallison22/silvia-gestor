import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fluxos_app_test.dart' hide main;

Future<void> tip(WidgetTester t, String tooltip) async {
  await t.tap(find.byTooltip(tooltip).first);
  await t.pumpAndSettle();
}

Future<void> createPiece(WidgetTester t) async {
  await openPiece(t);
  await fillPiece(t);
  await type(t, 'Largura (cm)', '150');
  await tapText(t, 'Salvar peça');
}

Future<void> createCrochet(WidgetTester t) async {
  await openCrochet(t);
  await type(t, 'Quantidade usada (g)', '50');
  await type(t, 'Tempo gasto (horas)', '1');
  await tapText(t, 'Salvar peça');
}

void main() {
  for (final bool crochet in [false, true]) {
    group(crochet ? 'venda crochê' : 'venda costura', () {
      final String key = crochet ? 'crochet_pieces' : 'pieces';
      Future<void> begin(WidgetTester t) async {
        await start(t, fabrics: [fabric()], yarns: [yarn()]);
        await (crochet ? createCrochet(t) : createPiece(t));
      }

      Future<double> stock() async => crochet
          ? (await saved('yarns')).single['stockWeightGrams'] as double
          : (await saved('fabrics')).single['stockLengthMeters'] as double;
      final double after = crochet ? 50 : 9;
      final double before = crochet ? 100 : 10;

      testWidgets('vender pelo sugerido e excluir não devolve material',
          (t) async {
        await begin(t);
        await tip(t, 'Marcar como vendida');
        await tapText(t, 'Confirmar venda');
        final Json p = (await saved(key)).single;
        expect(p['soldPrice'], p['suggestedPrice']);
        expect(p['soldAtIso'], isNotNull);
        await deletePiece(t);
        expect(await saved(key), isEmpty);
        expect(await stock(), closeTo(after, 1e-9));
      });

      testWidgets('desfazer venda e excluir devolve material', (t) async {
        await begin(t);
        await tip(t, 'Marcar como vendida');
        await type(t, 'Valor da venda (R\$)', '1.234,50');
        await tapText(t, 'Confirmar venda');
        expect((await saved(key)).single['soldPrice'], 1234.5);
        expect(find.textContaining('1.234,50'), findsNWidgets(2));
        await tip(t, 'Desfazer venda');
        await tapText(t, 'Desfazer');
        expect((await saved(key)).single['soldPrice'], isNull);
        await deletePiece(t);
        expect(await stock(), closeTo(before, 1e-9));
      });

      testWidgets('venda abaixo do custo avisa; detalhe mostra prejuizo',
          (t) async {
        await begin(t);
        await tip(t, 'Marcar como vendida');
        await type(t, 'Valor da venda (R\$)', '1');
        expect(find.textContaining('Abaixo do custo'), findsOneWidget);
        await tapText(t, 'Confirmar venda');
        await tapText(t, crochet ? 'Tapete' : 'Vestido');
        expect(find.text('Lucro da venda'), findsOneWidget);
      });

      for (final String bad in ['', 'abc', '-5']) {
        testWidgets('valor de venda "$bad" recusado', (t) async {
          await begin(t);
          await tip(t, 'Marcar como vendida');
          await type(t, 'Valor da venda (R\$)', bad);
          await tapText(t, 'Confirmar venda');
          expect((await saved(key)).single['soldPrice'], isNull);
        });
      }
    });
  }

  testWidgets('venda continua gravada ao reabrir o app', (t) async {
    await start(t, fabrics: [fabric()]);
    await createPiece(t);
    await tip(t, 'Marcar como vendida');
    await tapText(t, 'Confirmar venda');
    final List<Json> p = await saved('pieces');
    await t.pumpWidget(const SizedBox());
    await start(t, fabrics: [fabric()], pieces: p);
    await tapText(t, 'Costura');
    expect(find.text('Vendida por'), findsOneWidget);
  });

  testWidgets('peça antiga sem arredondamento vende em centavos', (t) async {
    await start(t, fabrics: [fabric()]);
    await createPiece(t);
    final Json p = (await saved('pieces')).single;
    p['suggestedPrice'] = 54.546327272727275;
    await t.pumpWidget(const SizedBox());
    await start(t, fabrics: [fabric()], pieces: [p]);
    await tapText(t, 'Costura');
    await tip(t, 'Marcar como vendida');
    expect(find.text('54,55'), findsOneWidget);
    await tapText(t, 'Confirmar venda');
    expect((await saved('pieces')).single['soldPrice'], 54.55);
  });

  group('reposicao', () {
    testWidgets('tecido: preço novo vale so para peças novas', (t) async {
      await start(t, fabrics: [fabric()]);
      await createPiece(t);
      final double oldCost = (await saved('pieces')).single['productionCost'];
      await tapText(t, 'Tecidos');
      await tapText(t, 'Algodao');
      await tapText(t, 'Adicionar metragem');
      await type(t, 'Metros a adicionar', '5');
      await type(t, 'Preço do metro nesta compra (R\$)', '40');
      await tapText(t, 'Adicionar');
      final Json f = (await saved('fabrics')).single;
      expect(f['stockLengthMeters'], closeTo(14, 1e-9));
      expect(f['pricePerMeter'], 40);
      await createPiece(t);
      final List<Json> ps = await saved('pieces');
      expect(ps[0]['productionCost'], oldCost);
      expect(ps[1]['productionCost'], closeTo(oldCost + 10, 0.011));
    });

    testWidgets('tecido: sem mudar preço mantem o exato', (t) async {
      await start(t, fabrics: [fabric(price: 33.333333333)]);
      await tapText(t, 'Algodao');
      await tapText(t, 'Adicionar metragem');
      await type(t, 'Metros a adicionar', '5');
      await tapText(t, 'Adicionar');
      expect((await saved('fabrics')).single['pricePerMeter'], 33.333333333);
    });

    testWidgets('tecido: preço em branco recusado', (t) async {
      await start(t, fabrics: [fabric()]);
      await tapText(t, 'Algodao');
      await tapText(t, 'Adicionar metragem');
      await type(t, 'Metros a adicionar', '5');
      await type(t, 'Preço do metro nesta compra (R\$)', '');
      await tapText(t, 'Adicionar');
      expect(await saved('fabrics').then((f) => f.single['stockLengthMeters']),
          10);
    });

    testWidgets('linha: reposicao com preço novo', (t) async {
      await start(t, yarns: [yarn()]);
      await tapText(t, 'Crochê');
      await tip(t, 'Adicionar estoque');
      await type(t, 'Preço do novelo de 200g (R\$)', '26,90');
      await tapText(t, 'Adicionar');
      final Json y = (await saved('yarns')).single;
      expect(y['skeinPrice'], 26.9);
      expect(y['stockWeightGrams'], 300);
    });

    testWidgets('linha: editar preserva id e estoque', (t) async {
      await start(t, yarns: [yarn(stock: 33.333333333)]);
      await tapText(t, 'Crochê');
      await tip(t, 'Editar linha');
      await type(t, 'Preço pago (R\$)', '30');
      await tapText(t, 'Salvar alterações');
      final Json y = (await saved('yarns')).single;
      expect(y['id'], 'y1');
      expect(y['skeinPrice'], 30);
      expect(y['stockWeightGrams'], 33.333333333);
    });

    testWidgets('linha: estoque em branco na edicao e recusado', (t) async {
      await start(t, yarns: [yarn()]);
      await tapText(t, 'Crochê');
      await tip(t, 'Editar linha');
      await type(t, 'Estoque atual (g)', '');
      await tapText(t, 'Salvar alterações');
      expect((await saved('yarns')).single['stockWeightGrams'], 100);
      expect(find.text('Editar Linha'), findsOneWidget);
    });
  });

  for (final double w in [320.0, 360.0, 412.0]) {
    testWidgets('peças vendidas com valores altos cabem em ${w}px', (t) async {
      await start(t,
          size: Size(w, 3000),
          fabrics: [fabric(stock: 5000, price: 90000)],
          yarns: [yarn()]);
      await createPiece(t);
      await tip(t, 'Marcar como vendida');
      await tapText(t, 'Confirmar venda');
      expect(t.takeException(), isNull);
      await createCrochet(t);
      await tip(t, 'Marcar como vendida');
      await tapText(t, 'Confirmar venda');
      expect(t.takeException(), isNull);
      await tapText(t, 'Tecidos');
      expect(t.takeException(), isNull);
    });
  }
}
