# sogra_loja

Aplicativo Flutter para:
- Cadastrar tecidos comprados e controlar estoque.
- Registrar pecas produzidas consumindo tecido do estoque.
- Calcular custo de tecido por area e preco final de venda usando 4 pilares:
  - Mao de Obra
  - Custos Fixos
  - Materiais
  - Lucro

## Regras principais
- O estoque e persistido localmente no dispositivo.
- Ao criar peca, o app calcula:
  - Area usada (largura x comprimento)
  - Metros lineares equivalentes consumidos (area / largura do tecido)
  - Custo do tecido consumido
- Preco sugerido considera:
  - Valor da hora = salario mensal / horas mensais
  - Custo de trabalho = horas da peca x valor da hora
  - Custo operacional = custo de trabalho + % custos fixos
  - Custo de producao = custo operacional + materiais
  - Preco final sugerido = custo de producao + % lucro
