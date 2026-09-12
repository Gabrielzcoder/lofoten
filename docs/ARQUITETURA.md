# Arquitetura técnica

## Objetivo do protótipo

Esta versão valida o ciclo central: explorar as três regiões, ouvir moradores,
entrar no escritório, tomar duas decisões e observar o próximo dia e as mudanças
da ilha. O projeto usa apenas Godot 4.x e GDScript.

## Cenas e nós

```text
Main (Node2D)
├── Background (Sprite2D)
├── NPCs (Node2D)
├── Interactables (Node2D)
├── Player (CharacterBody2D)
│   ├── CollisionShape2D
│   ├── Body (Polygon2D)
│   │   ├── Head (Polygon2D)
│   │   └── Tie (Polygon2D)
│   └── InteractionArea (Area2D)
│       └── CollisionShape2D
├── HUD (CanvasLayer)
├── DialogueUI (CanvasLayer)
├── DecisionUI (CanvasLayer)
├── MainMenu (CanvasLayer)
├── EndingUI (CanvasLayer)
└── LoadingScreen (CanvasLayer)
```

NPC e OfficeDoor são cenas reutilizáveis do tipo `Area2D`, derivadas da classe
`Interactable`. Cada uma possui sua própria colisão e implementa seu comportamento.

## Autoloads

- `GameState`: fonte única dos atributos globais, eventos, finais e save/load.
- `DayManager`: ciclo diário, número de decisões e custos automáticos do dia.

Ambos já estão registrados em `project.godot`; não há configuração manual.

## Comunicação

Os sistemas se comunicam por sinais. O Player detecta um `Interactable` e solicita
a interação; Main escolhe a interface adequada. As interfaces emitem o resultado
sem conhecer o mapa. `GameState.state_changed` atualiza o HUD e permite que outros
sistemas reajam ao estado global.

## Dados

As decisões ficam em `data/decisions.json`. Cada entrada possui identificador,
título, contexto, escolhas e um dicionário de efeitos. Novas decisões podem ser
incluídas sem alterar a interface.

Os NPCs já usam falas condicionais para ambiente, economia e diversificação. Em uma
próxima fase, as definições dos NPCs também podem migrar para JSON ou Resources.

## Mudanças visuais

Cada região aponta para duas imagens: normal e degradada. Quando o atributo Ambiente
fica abaixo de 50, Main troca a imagem carregada. O mecanismo é modular: podem ser
adicionados outros níveis e elementos sobrepostos sem alterar decisões ou NPCs.

## Ordem recomendada das próximas fases

1. Agenda de NPCs e eventos por região.
2. Requisitos e encadeamento mais longo de decisões.
3. Mais níveis de mudança visual e efeitos sonoros.
4. Opções e múltiplos slots de save.
5. Balanceamento dos quatro finais e polimento adicional.
