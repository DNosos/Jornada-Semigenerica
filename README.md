# Jornada Semigenérica

**Plataforma 2D em pixel art**, desenvolvido por Arthur Augusto e Emanuel Nepomuceno.

## História

Um herói parte em direção ao castelo do Rei Demônio para resgatar a princesa. A jornada é dividida em três regiões, cada uma com inimigos e obstáculos mais difíceis.

## Como jogar

| Ação | Controle |
|---|---|
| Andar para a esquerda | A |
| Andar para a direita | D |
| Pular | W ou Espaço |
| Acelerar a descida | S |
| Atacar | Botão esquerdo do mouse |
| Conversar / interagir | F |
| Avançar o diálogo | F ou Enter |

Os diálogos são lineares: não há escolhas de respostas. Aproxime-se de um NPC e pressione **F**.

## Progressão

1. **Trilha da Floresta (tutorial):** conversa com a mestra, primeiro contato com o ferreiro, moedas, poções, zumbis, servos e espinhos.
2. **Ruínas Esquecidas:** inimigos mais resistentes, polvo, mago viajante, plataformas e novo checkpoint.
3. **Castelo do Rei Demônio:** última região, servos, mago, checkpoint e batalha contra o Rei Demônio. Após vencê-lo, converse com a princesa para concluir a campanha.

## Sistemas implementados

- Movimento, pulo, queda acelerada e câmera que acompanha o jogador.
- Ataque corpo a corpo com hitbox direcional e dano aos inimigos.
- Inimigos com patrulha, perseguição, vida e contato que causa dano.
- Barra de vida, invulnerabilidade temporária após receber dano e retorno após perder toda a vida.
- Checkpoints por região: ao ser derrotado, o herói retorna ao último ponto ativado.
- Moedas, poções de cura e melhorias de espada compradas com o ferreiro.
- NPCs com caixas de diálogo reutilizáveis e falas específicas por personagem.
- Três regiões conectadas e chefe final com barra de vida.
- Menu com opções de controles e créditos.

## Recursos

Os sprites dos personagens, inimigos e itens ficam em `Image's/assets/`. Os tilesets e referências visuais ficam em `Image's/TileMaps/`. O projeto usa os spritesheets existentes do jogador e as fontes que já estavam no repositório.

## Executar

Abra `project.godot` no **Godot 4.x** e execute o projeto (F6 para testar a cena atual ou F5 para iniciar pelo menu).

## Créditos

- Desenvolvimento: Arthur Augusto e Emanuel "DNosos" Nepomuceno.
- Referência conceitual: *Jornada Genérica*.
