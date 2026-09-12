# Lofoten — jogo narrativo em Godot 4.x

Jogo narrativo 2D com três regiões, exploração lateral, quatro gatos NPCs,
diálogos reativos, decisões administrativas, ciclo de dias, consequências visuais,
quatro finais, transições e save/load.

## Abrir

1. Abra o Godot 4.x.
2. Clique em **Importar**.
3. Selecione o arquivo `project.godot` desta pasta.
4. Clique em **Importar e editar** e depois em **Executar projeto** (F6/F5 no editor).

## Controles

- `A`/`D` ou setas: mover.
- `E`: interagir e avançar diálogos.
- `F5`: salvar.
- `F9`: carregar.
- A indicação de interação só aparece quando há algo próximo.

## Primeiro teste

Comece na Cidade Baixa, converse com os moradores e caminhe pelas bordas até a
Cidade Alta. A porta do escritório fica na casa à esquerda, marcada como sede da
diretoria. Tome duas decisões;
isso encerra o dia, consome petróleo e aplica consequências. Decisões que derrubam
o ambiente abaixo de 50 trocam os cenários para as versões degradadas.

As consequências numéricas não aparecem antes das escolhas. O estado da ilha é
revelado pelos cenários, eventos e falas dos moradores. A HUD mantém somente o que
o protagonista saberia com precisão: dia, caixa da empresa e reserva de petróleo.

Na exploração, Player e NPCs usam pixel art minimalista. As quatro ilustrações
detalhadas aparecem exclusivamente como portraits durante os diálogos.

## Estrutura principal

- `scripts/autoload`: estado global e gerenciador de dias.
- `scripts/player`: movimento e detecção de interação.
- `scripts/world`: objetos interativos.
- `scripts/npc`: NPCs e falas condicionais.
- `scripts/ui`: HUD, diálogo e decisões.
- `data/decisions.json`: decisões orientadas a dados.
- `assets/backgrounds`: imagens fornecidas para as três regiões.
- `assets/characters`: protagonista e NPCs felinos criados para o jogo.
- `assets/ui/island_theme.tres`: linguagem visual compartilhada pelas interfaces.
- `scenes/ui/LoadingScreen.tscn`: abertura e transições temáticas.
- `scenes/ui/EndingUI.tscn`: conclusão real da partida e explicação do resultado.
- `scenes/ui/MainMenu.tscn`: retorno após o final, reinício, load e saída.
