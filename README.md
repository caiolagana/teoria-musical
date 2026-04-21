# Teoria Musical

Programa interativo em Python para construção de escalas, acordes e visualização de digitações em instrumentos de corda.

## Funcionalidades

- **Escalas**: maior, menor (natural, harmônica, melódica), pentatônicas, blues, modos gregos (dórica, frígia, lídia, mixolídia, lócria), cromática
- **Acordes**: tríades (maior, menor, diminuto, aumentado), tétrades (7M, 7, m7, m7b5, dim7), sus2, sus4, acordes com nona
- **Intervalos**: cálculo de intervalos entre duas notas com nome em português
- **Instrumentos**: digitação de acordes e diagrama do braço para escalas, com suporte a múltiplas afinações

## Afinações incluídas

| Nome | Cordas |
|------|--------|
| viola_caipira_rio_abaixo | G-D-G-B-D |
| viola_caipira_cebolao_D | A-D-F#-A-D |
| viola_caipira_cebolao_E | E-B-G#-E-B |

Para adicionar novas afinações, edite o dicionário `TUNINGS` em `main.py`.

## Como usar

```bash
python3 main.py
```

O menu interativo oferece três opções:

1. **Montar escala** — escolha a tônica e o tipo de escala. Exibe as notas, intervalos e o diagrama do braço para cada afinação cadastrada.
2. **Montar acorde** — escolha a tônica e o tipo de acorde. Exibe as notas, intervalos e a digitação (trastes) para cada afinação.
3. **Calcular intervalo** — informe duas notas e veja a distância em semitons.

## Exemplo de saída

```
  Escala maior de G
  ------------------
    G - A - B - C - D - E - F# - G

  viola_caipira_rio_abaixo — escala de G

       ||   0   1   2   3   4   5   6   7   8   9  10  11  12  13  14
G (1ª) || [G]   ·   A   ·   B   C   ·   D   ·   E   ·  F# [G]   ·   A
D (2ª) ||   D   ·   E   ·  F# [G]   ·   A   ·   B   C   ·   D   ·   E
G (3ª) || [G]   ·   A   ·   B   C   ·   D   ·   E   ·  F# [G]   ·   A
B (4ª) ||   B   C   ·   D   ·   E   ·  F# [G]   ·   A   ·   B   C   ·
D (5ª) ||   D   ·   E   ·  F# [G]   ·   A   ·   B   C   ·   D   ·   E
```

## Requisitos

Python 3.10+. Sem dependências externas.
