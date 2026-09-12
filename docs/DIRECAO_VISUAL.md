# Direção visual — etapa 2

## Identidade

A interface combina azul-petróleo, marfim, cobre e âmbar. Os painéis escuros evocam
madeira pintada, metal naval e documentos da diretoria, mantendo contraste alto
sobre os cenários pixel art. Cantos, bordas, espaçamentos e estados de botão vêm de
um único Theme reutilizável.

## Personagens

O mundo é habitado por gatos antropomórficos. Na exploração, uma folha minimalista
apresenta os quatro NPCs em pixel art compacta: trabalhador, moradora de casaco
verde, assessora de sobretudo vermelho e executivo da Cidade Alta. As artes grandes
e detalhadas são reservadas exclusivamente aos portraits de diálogo.

O Player possui uma folha própria com um quadro de idle e três quadros de caminhada.
A animação para a esquerda reutiliza os mesmos frames por espelhamento horizontal.

## Linhas de chão

- Cidade Alta: `y = 700`.
- Ponte: `y = 552`.
- Cidade Baixa: `y = 708`.

Cada região possui seu próprio alinhamento; os pés, sombras e colisões usam a origem
do Node principal como linha de apoio.

## Interface

- HUD reduzida a localização, dia, caixa e petróleo.
- Atributos sociais, ambientais e econômicos permanecem internos.
- Decisões mostram apenas linguagem narrativa, nunca os efeitos calculados.
- Diálogos usam retrato do gato, hierarquia tipográfica e animação curta.
- Loading screen temática é usada na abertura, viagens e passagem do dia.
- Não existe barra de progresso falsa; a tela usa um indicador temático durante os
  fades rápidos de cenas já carregadas.
