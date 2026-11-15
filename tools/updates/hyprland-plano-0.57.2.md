# Plano: Hyprland 0.55.4 → 0.57.2

Alvo = versão do `nixos-unstable` (rev `d4f25a3e562008648d45bcf2d70bcc7422cad84e`), igual à última tag upstream.
glibc da rev nova (2.44) não passa a do `nixpkgs` do sistema: não precisa atualizar o grupo Sistema antes.

## Teste direto

`--verify-config` do 0.57.2 sobre a config atual: **config ok**. Só prova sintaxe/API.

## O que quebra

Nada encontrado. Cruzamento do changelog (0.56.0 a 0.57.2) e do diff de `src/config` com o nosso uso:

| Mudança upstream | Nosso uso | Resultado |
|---|---|---|
| Evento Lua `created` → `created_early` | só usamos `hl.on("hyprland.start")` (`execs.lua:1`), que continua em `LuaEventHandler.cpp:157` | não afeta |
| `dampening` → `damping` (springs) | só curvas bezier (`general.lua:155-157`) | não afeta |
| Dispatcher factory rejeitada em bind/dispatch | todos os binds chamam a factory (`hl.dsp.x(...)`); `hl.dispatch(hl.dsp.focus(...))` também | não afeta |
| Workspaces com nome igual a ID rejeitados | só `"1"`..`"9"` numéricos e `name:gaming` (comentário) | não afeta |
| Maximize ao mapear removido | nenhuma regra/uso de maximize | não afeta |
| `misc` → `layers` (2 opções) | as 2 são `layers:allow_new_top_layers_over_existing_fullscreen` e `layers:layers_hog_keyboard_focus`; não usamos | não afeta |
| `hl.notification` exige timeout | não usamos | não afeta |
| `hyprctl monitors` com scale sem arredondar | scripts só leem `.name` (`set_wallpaper.sh:30`) | não afeta |
| `hyprctl eval`, `dispatch "hl.dsp...."`, `reload`, `kill`, `setcursor` | continuam registrados (`ipc/s1/Commands.cpp`) | não afeta |
| `.conf` do Hyprland deprecado/removido | só `hyprpaper.conf`, que é do hyprpaper | não afeta |
| `no_hardware_cursors` default → 2 | já fixamos `0` (`general.lua:130`) | não afeta |
| Monitores com defaults novos | os dois monitores têm modo, posição e scale explícitos | não afeta |

## Muda de comportamento (não quebra)

1. **`misc:new_float_force_onscreen` (opção nova, default 2):** janelas flutuantes novas passam a ser forçadas para dentro da tela. Hoje não há esse comportamento.
   - Proposta para ficar igual a hoje: `new_float_force_onscreen = 0` em `misc` (`general.lua`, bloco `misc`).
   - Obs.: os monitores ficam em `0x0` e `25600x0` (longe um do outro), então o efeito prático tende a ser pequeno; a linha só garante a paridade.
2. **Layers de topo ficam abaixo de fullscreen** (e `layers:allow_new_top_layers_over_existing_fullscreen` controla isso). Pode mudar se algo (notificação, barra) aparecia sobre jogo em tela cheia. Sem mudança proposta; **conferir na finalização**.
3. **Scroll em binds:** direção da roda corrigida. Nossos binds de `mouse_up/down` só chamam `true` (bloqueio), então não muda nada.
4. `hl.on("window.open")`/`created` mudaram de timing; não usamos.

## Não dá para manter igual

Nada.

## Fora de propósito

- `misc:session_lock_blur`, `bell_sound`, `float_force_onscreen` (default 0): novas, defaults já equivalentes.
- Nenhuma adoção de recurso novo (wobble, glow, layers etc.).

## Mudanças no patch

- `config/hypr/hyprland/general.lua`: `misc.new_float_force_onscreen = 0`.

## Só o build do botão valida

- Nada em `.nix` muda no patch. A troca de rev do `nixpkgs-hyprland`/`nixpkgs-mesa`, `CLAUDE.md` e a regra do Hyprland ficam a cargo do botão.

## Na finalização conferir

- Thunar (as duas grafias da classe), `hyprctl configerrors` vazio, comportamento de layers sobre fullscreen em jogo.
- Pastas da wiki agora têm nome em minúsculas (`configuring/`): checar caminhos citados em docs.
