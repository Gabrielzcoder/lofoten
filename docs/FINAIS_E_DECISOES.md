# Decisões, estado e finais

## Estado interno

Além dos atributos existentes, o jogo agora mantém `employment` (Emprego) e um
histórico com decisão, alternativa e dia. Isso permite que os NPCs respondam à ação
realmente escolhida, e não apenas ao valor atual de uma barra.

## Lógica das decisões

- **Contrato do Mar do Norte:** o turno extra aumenta produção, caixa, emprego e
  economia, mas consome reservas e piora o ambiente. Recusar protege os poços, com
  custo corporativo e pequeno recuo do emprego.
- **Parque eólico:** investimento completo custa mais e reduz capacidade imediata,
  porém cria emprego e diversificação rapidamente. O piloto reduz riscos e ganhos.
- **Filtros:** a instalação completa melhora muito o ar, mas interrompe produção. A
  instalação gradual preserva turnos e entrega uma melhora ambiental menor.
- **Turismo:** bolsas aceleram novas fontes de renda, retirando pessoal e dinheiro da
  indústria. O programa de fim de semana faz uma transição mais lenta.
- **Vazamento:** suspender o cais protege a baía e a confiança pública, mas perde
  entregas e turnos. Manter embarques protege o trimestre e amplia o dano ambiental.
- **Crédito local:** negócios independentes diversificam e criam mais empregos; o
  crédito restrito a fornecedores retorna mais valor à refinaria, mas mantém a
  dependência do petróleo.

## Condições dos finais

1. **O Futuro de Lofoten — sustentável:** petróleo ≤ 15, diversificação ≥ 65,
   economia ≥ 45 e ambiente ≥ 35.
2. **O Último Balanço — corporativo:** ambiente ≤ 15, caixa ≥ 220 e aprovação da
   empresa ≥ 55.
3. **A Porta do Conselho — demissão:** aprovação da empresa ≤ 8.
4. **Porto sem Luzes — colapso:** petróleo ≤ 5 com diversificação < 45, ou economia
   ≤ 10, ou caixa ≤ -50.

Ao ocorrer um final, GameState é marcado como encerrado, a fila de decisões é limpa,
o Player é bloqueado e `EndingUI` apresenta resumo, causas derivadas do estado e das
escolhas, valores finais e opções de reinício ou menu.

## Configuração manual

Nenhuma. As cenas, scripts, folhas, animações, colisões e interfaces já estão
referenciados no projeto.
