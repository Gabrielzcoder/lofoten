# Assets gerados para a etapa 2

Modo utilizado: ferramenta integrada de geração de imagens, com transparência real.
Os três cenários claros fornecidos foram usados somente como referência de estilo.

## Prompts finais

1. **cat_director.png** — gato executivo cinza-carvão, corpo inteiro, casaco azul-
   petróleo, camisa marfim, gravata cobre e pasta de couro; pixel art nórdica,
   silhueta isolada, pés em linha de base horizontal e fundo transparente.
2. **cat_adviser.png** — gata calico assessora econômica, corpo inteiro, sobretudo
   bordô, pasta azul e broche de latão; mesma densidade de pixel, linha de base e
   transparência.
3. **cat_worker.png** — gato tabby laranja operador de refinaria, macacão azul,
   botas, faixa refletiva e capacete amarelo; corpo inteiro e fundo transparente.
4. **cat_reporter.png** — gato tabby prateado jornalista, casaco verde-musgo, cachecol
   ferrugem, caderno e bolsa; corpo inteiro e fundo transparente.

Restrições comuns: um personagem por imagem, sem cenário, texto, moldura, sombra ou
cortes; estilo pixel art coerente com os fundos existentes.

## Folhas de exploração — etapa 3

Modo utilizado: ferramenta integrada de geração de imagens, seguida por uma edição
de extração de fundo na própria ferramenta para garantir canal alfa real.

5. **npc_overworld_sheet.png** — uma linha com quatro células: operário laranja,
   gata prateada de casaco verde, gata calico de sobretudo vermelho e executivo
   cinza. Personagens simplificados, paleta limitada, mesma altura e linha de pés.
6. **player_overworld_sheet.png** — quatro células do protagonista tuxedo: idle,
   contato da passada, passagem e contato oposto, todos orientados para a direita.
   A direção esquerda é criada pelo Godot com `flip_h`.

Prompt comum: sprites pequenos de RPG narrativo, pixels grandes, poucos detalhes,
silhuetas reconhecíveis, células iguais, fundo transparente real, sem texto, cenário,
sombra ou linhas de grade.

## Correção de escala e estilo

7. **npc_overworld_sheet_v3.png** — substituição final da folha dos NPCs. Usa as
   mesmas células de 512×768 e o mesmo estilo minimalista do Player. No mapa, a
   altura visível dos NPCs é equivalente à altura do Player; somente os portraits
   de diálogo mantêm o nível alto de detalhe.
