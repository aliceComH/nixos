<!--
Template para novos knowledge docs. Copie este arquivo para
.agents/knowledge/<nome-do-subsistema>.md e preencha as seções.
Não delete este comentário nos docs gerados a partir daqui.
-->

# Minecraft Java (Prism Launcher)

## O que é

Minecraft Java pelo Prism Launcher (Fabric + Sodium/Iris/Distant Horizons),
jogado no workspace 5 em fullscreen com direct scanout.

## Por que existe

O Prism traz os JDKs no wrapper do nixpkgs e baixa os mods pelo Modrinth. Por
isso o lado do NixOS é só o pacote, o atalho e as windowrules. Instâncias, mods
e shaders ficam em `~/.local/share/PrismLauncher/` e não são declarados no Nix.

## Arquivos envolvidos

- `modules/nixos/programs.nix` — `prismlauncher` na lista `apps` (`pkgs-apps`, grupo Programas).
- `config/hypr/hyprland/keybinds.lua` — `ALT + M` → `prismlauncher` no escopo global e nos submaps
  (menos `gaming`/`osu`).
- `config/hypr/hyprland/windowrules/workspace-5-gaming.lua` — o Prism
  (`org.prismlauncher.PrismLauncher`) abre flutuando e centralizado no 5, sem
  `silent`. O jogo (`^(Minecraft\*? [0-9].*)$`, via XWayland) vai para `5 silent`
  com `fullscreen`, `content = "game"`, `immediate`, sem blur/shadow e com
  `idle_inhibit`.
- `config/hypr/hyprland/scripts/gaming_monitor.sh` — liga `render.direct_scanout`
  ao entrar no 5 e desliga nos outros workspaces.

## Depende de / Relacionado a

- **Forte:** `gaming_monitor.sh`. Sem ele, `direct_scanout` fica em 0 (o valor de
  `general.lua`) e não há scanout direto.
- **Fraco:** [minecraft-bedrock](minecraft-bedrock.md) — mesmo workspace e mesmo padrão
  de regras; a regex da class não pega `Minecraft.Windows.exe`.
- **Fraco:** [updates](updates.md) — o pacote segue `nixpkgs-apps`.

## Pontos de atenção

- A class muda a cada versão do jogo (`Minecraft* 1.21.1`), por isso a regex.
  O `*` só aparece com mods.
- Para conferir: `hyprctl monitors -j`, campos `directScanoutTo` e
  `directScanoutBlockedBy` (vazio = ativo). O tearing aparece como bloqueado por
  `HW_CURSOR` enquanto o cursor está visível (menu ou pause); isso é esperado.
- Regras estáticas (`immediate`, `content`, `workspace`) só valem para janelas
  abertas depois do reload.
- "String too big (was 20 characters, max 16)" ao entrar em um mundo = a conta
  Microsoft não tem perfil Java. Não é bug de mod.
