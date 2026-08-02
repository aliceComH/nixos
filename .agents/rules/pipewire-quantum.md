---
trigger: always_on
---

# Regra Inviolável: Quantum e Rate do PipeWire

## Por que existe

O graph de áudio deste sistema foi calibrado para **baixíssima latência** e **um único clock estável**. O osu! depende de quantum mínimo (32 via ALSA, graph em 64). Aumentar quantum ou relaxar o clock causa subsampling, drift e degradação perceptível no timing de áudio — não só no osu!, mas em todo o graph que compartilha o mesmo clock.

**Esta regra tem precedência sobre qualquer outra sugestão de "otimização" de áudio.**

## Valores fixos — NUNCA alterar

| Propriedade | Valor | Onde |
|---|---|---|
| `default.clock.rate` | `48000` | `modules/nixos/services.nix` → `10-clock` |
| `default.clock.force-rate` | `48000` | idem |
| `default.clock.allowed-rates` | `[ 48000 ]` | idem |
| `default.clock.quantum` | `64` | idem |
| `default.clock.force-quantum` | `64` | idem |
| `default.clock.min-quantum` | `32` | idem |
| `default.clock.max-quantum` | `64` | idem |
| osu! ALSA (`alsa_playback.*`) | `node.force-quantum = 32`, `node.latency = "32/48000"` | `services.nix` → `11-alsa-force` |

## O que é proibido

- Aumentar `max-quantum`, `force-quantum` ou `default.clock.quantum` (global ou por nó)
- Remover `force-quantum` global "para dar folga" a filter-chains ou sinks virtuais
- Pedir `node.latency` acima de `64/48000` em qualquer módulo PipeWire
- Adicionar `allowed-rates` com 44100 ou permitir rate switching no graph
- Sugerir "só neste sink" com quantum maior — o graph compartilha o mesmo clock

## O que fazer em vez disso

Quando áudio craqueia, estoura CPU ou precisa de mais headroom de processamento:

1. **Reduzir carga DSP** — menos plugins LADSPA, chain mais curto, parâmetros menos agressivos
2. **Ajustar parâmetros dos plugins** — attack/release do compressor/limiter, makeup gain, threshold
3. **Isolar o problema** — testar sem filter-chain, verificar se é artefato de ganho (zipper/pumping) e não xrun
4. **Prioridade RT** — já configurada via `libpipewire-module-rt` e grupo `@audio`; não compensar com buffer maior

## Arquivos afetados

Qualquer mudança em áudio deve respeitar esta regra, especialmente:

- `modules/nixos/services.nix`
- `modules/nixos/voice-normalizer.nix`
- `modules/home/audio-mirror.nix` (loopbacks já usam `--quantum 64`)
- `modules/nixos/packages-system.nix` (wrapper osu! / PIPEWIRE_ALSA)

## Checklist antes de commitar mudanças de áudio

- [ ] `force-quantum` continua `64` no clock global?
- [ ] `max-quantum` continua `64`?
- [ ] Nenhum nó novo pede latency/quantum > 64?
- [ ] Rate continua travado em 48000?
- [ ] Regra do osu! (`11-alsa-force`) intacta?
