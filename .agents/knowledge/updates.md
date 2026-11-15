<!--
Template para novos knowledge docs. Copie este arquivo para
.agents/knowledge/<nome-do-subsistema>.md e preencha as seções.
Não delete este comentário nos docs gerados a partir daqui.
-->

# Updates (grupos de atualização + Central de Updates)

## O que é

Divisão do sistema em quatro grupos que atualizam de forma independente, cada um
com os seus inputs do flake, mais uma GUI GTK3 com um botão por grupo.

## Por que existe

Antes tudo saía de um único `nixpkgs`: atualizar um programa atualizava kernel e
drivers junto. Em Nix, "atualizar separado" só existe com inputs separados, então
cada grupo ganhou o seu. Drivers e ferramentas ficaram no MESMO grupo de
propósito: kernel, Mesa, systemd, PipeWire e o userland base saem de uma única
avaliação do NixOS (o `pkgs` do sistema) e não dá para separá-los sem instanciar
o NixOS duas vezes.

| Grupo | Inputs | Módulos |
|---|---|---|
| Hyprland | `nixpkgs-hyprland` (rev fixa na URL) + `nixpkgs-mesa` (rev fixa, só a Mesa) | `modules/nixos/hyprland-system.nix`, `hardware.graphics.package` em `amd-gpu.nix` |
| osu! | `nixpkgs-osu` | `modules/nixos/osu.nix` |
| Sistema (drivers + ferramentas) | `nixpkgs`, `home-manager` | `packages-system.nix`, `modules/home/packages-home.nix`, `amd-gpu.nix`, `kernel-zen.nix`, `services.nix` e todo o resto |
| Programas | `nixpkgs-apps`, `claude-desktop`, `bedrock-on-linux` | `modules/nixos/programs.nix`, `minecraft-bedrock.nix`, flatpaks |

## Arquivos envolvidos

- `flake.nix` — define os inputs e instancia `pkgs-apps`, `pkgs-osu`, `pkgs-hyprland`, `pkgs-mesa` (passados por `specialArgs`).
- `modules/nixos/amd-gpu.nix` — `hardware.graphics.package{,32}` vêm de `pkgs-mesa`; asserção de glibc Hyprland >= glibc da Mesa.
- `modules/nixos/programs.nix` — apps, todos de `pkgs-apps` (inclui o wrapper do mpv).
- `modules/nixos/packages-system.nix` — ferramentas, do `pkgs` base.
- `modules/nixos/osu.nix` — wrapper do osu-lazer, de `pkgs-osu`.
- `modules/nixos/update-groups.nix` — opção `local.updateGroups.<grupo>` (informativa, não instala) e gera `/etc/update-groups.json`; também declara a lista de drivers.
- `tools/updates/update-group.sh` — fonte da verdade do mapeamento grupo → inputs; atualiza, faz build, mostra `nix store diff-closures`, pergunta e só então roda `sudo nixos-rebuild switch`.
- `tools/updates/updates.py` — GUI; lê `flake.lock` e `/etc/update-groups.json` e abre o script num kitty.

## Depende de / Relacionado a

- **Forte:** [mpv](mpv.md) — o build do mpv vive em `programs.nix` e usa `pkgs-apps`.
- **Fraco:** [minecraft-bedrock](minecraft-bedrock.md) — o input segue `nixpkgs-apps` e atualiza com os Programas.

## Pontos de atenção

- O mapeamento grupo → inputs (fora o `nixpkgs-mesa`, que só existe em `flake.nix`) está em três lugares: `update-group.sh` (verdade), `GROUPS` em `updates.py` e o comentário no topo de `flake.nix`. Mudou um, mude os três.
- Programa novo vai em `programs.nix` com `pkgs-apps`, não em `packages-system.nix`. Colocar um app na lista de ferramentas faz ele atualizar junto com kernel/drivers.
- `pkgs-apps` não recebe os overlays de `nixpkgs.overlays` (openldap, libratbag): eles só valem para o `pkgs` base.
- **A Mesa não atualiza com o Sistema.** Tudo que roda faz dlopen da Mesa de `/run/opengl-driver`, e ela só carrega em processos com glibc >= a glibc com que foi compilada. O binário mais velho do sistema é o Hyprland travado (glibc 2.42), então a Mesa fica travada em `nixpkgs-mesa` (26.2.1, rev de 2026-08-31). Em 2026-11-13 o update do Sistema trouxe a Mesa 26.3.0 (glibc 2.44): a sessão aberta seguiu viva, mas no boot seguinte o Hyprland abortava em `CBackend::create()` ("Couldn't open a GBM device" no crash report em `~/.cache/hyprland/`). A asserção em `amd-gpu.nix` agora quebra o build se isso se repetir.
- Para subir a Mesa: ou atualiza o Hyprland (aí `nixpkgs-mesa` pode ir para uma rev com glibc <= a nova do Hyprland), ou não sobe. "Atualizar Hyprland" em `update-group.sh` NÃO mexe em `nixpkgs-mesa`; é manual.
- Pela mesma razão, um app de `pkgs-apps`/`pkgs-osu` mais antigo que a Mesa falharia igual; com a Mesa travada no mais velho, esse caso some.
- A seção "drivers" da Central mostra a Mesa em uso (`config.hardware.graphics.package`), não a do `pkgs`.
- `kitty` e `pavucontrol` ficaram no `pkgs` base de propósito: o terminal roda os updates. Steam e Thunar também (via `programs.<x>.enable` em `services.nix`).
- `nix flake update` sem argumentos atualiza TODOS os grupos de uma vez (menos o Hyprland, travado por rev). Use sempre com o nome dos inputs.
- "Atualizar Hyprland" edita a rev em `flake.nix` via `sed`. Depois disso a wiki/código-fonte locais, o `CLAUDE.md` e `.agents/rules/hyprland-guidelines.md` ficam desatualizados e precisam ser trocados à mão.
- O script não commita: `flake.lock` fica modificado até a Alice pedir o commit.
- `/etc/update-groups.json` reflete o sistema ATIVO; só muda depois de um rebuild.
- A GUI não tem keybind nem windowrule ainda (a claudia usa `ALT + 6` e a regra em `workspace-8-auxiliar.lua`).
