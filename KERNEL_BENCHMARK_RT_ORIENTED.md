# Benchmark: linux_7_0 RT-oriented vs zen

Objetivo: comparar consistencia temporal (frametime/jitter/audio) entre o perfil
RT-oriented em `linux_7_0` e o fallback `linuxPackages_zen`.

## Preparacao

1. Reinicia e entra no perfil principal (RT-oriented).
2. Faz warm-up de 2-3 minutos com o jogo aberto.
3. Mantem cenario fixo em todos os testes:
   - mesma resolucao, FPS cap e skin;
   - mesmo servidor grafico (X11 ou Wayland);
   - sem apps pesadas em background.

## Coleta por sessao

Repete 3x por mapa (1 mapa denso + 1 mapa tecnico):

- `Avg FPS`
- `1% low`
- `Frametime p95/p99`
- `XRUNs` (PipeWire)
- nota subjetiva de input (0-10)
- ocorrencia de micro-stutter (sim/nao + observacao)

## Comandos uteis

Ver kernel ativo:

```bash
uname -r
```

Monitorar audio/PipeWire:

```bash
pw-top
```

Opcional para OSD de frametime/FPS:

```bash
mangohud <comando-do-osu-lazer>
```

## Rodada em fallback zen

1. Reinicia e seleciona no boot a especializacao `zen-fallback`.
2. Repete exatamente os mesmos mapas e condicoes.

## Criterio de decisao

Escolher o perfil com prioridade em:

1. menor p95/p99 de frametime;
2. menor jitter perceptivel de input;
3. menos XRUNs/audio crackle;
4. empate tecnico em FPS medio.
