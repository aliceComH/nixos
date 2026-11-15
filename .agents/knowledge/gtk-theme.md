<!--
Template para novos knowledge docs. Copie este arquivo para
.agents/knowledge/<nome-do-subsistema>.md e preencha as seções.
Não delete este comentário nos docs gerados a partir daqui.
-->

# gtk-theme (tema GTK, ícones e visual do Thunar)

## O que é

Tema e ícones dos apps GTK: `adw-gtk3-dark` repintado por cores nomeadas com uma
paleta escura quente (inspirada no tema dark do Claude). Vale para todos os apps
GTK3/GTK4, não só o Thunar.

## Por que existe

A Alice achava o Thunar claro demais e os ícones feios. A causa dos ícones era
estrutural: no Wayland o GTK3 lê tema e ícones do gsettings
(`org.gnome.desktop.interface`) e ignora `gtk-theme-name`/`gtk-icon-theme-name`
do `settings.ini`. Com o dconf vazio ele usava "Adwaita" (sem ícones instalados),
então o `Papirus-Dark` do `settings.ini` nunca valeu.

## Arquivos envolvidos

- `modules/home/gtk-theme.nix` — `dconf.settings` com `gtk-theme`, `icon-theme` e `color-scheme`. É o que vale de fato para GTK3/GTK4.
- `config/gtk-3.0/settings.ini`, `config/gtk-4.0/settings.ini` — mesmos valores, como fallback (X11/apps sem gsettings). Manter em sincronia com o dconf.
- `config/gtk-3.0/gtk.css` — escrito à mão (não é mais do Matugen): bloco `@define-color` lido pelo `adw-gtk3-dark`, mais ajustes só de GTK3 (seleção e rubberband translúcidos).
- `config/gtk-4.0/gtk.css` — só o bloco `@define-color`, para libadwaita. Manter igual ao do GTK3.
- `modules/nixos/packages-system.nix` — `adw-gtk3` (tema), `colloid-icon-theme` (em uso) e `papirus-icon-theme` (fallback).
- `config/hypr/hyprland/windowrules/general.lua` — opacidade do Thunar (0.85).
- `config/hypr/hyprland/windowrules/floating.lua` — float, tamanho e centro do Thunar, e o diálogo "Criar nova pasta".
- `home/alice/home.nix` — importa `gtk-theme.nix`.

## Depende de / Relacionado a

- **Forte:** `programs.dconf.enable` em `modules/nixos/services.nix` — sem o dconf o Home Manager não grava as chaves.
- **Fraco:** Kvantum (`config/Kvantum/Colloid`) — apps Qt usam o mesmo nome de tema, sem ligação técnica.

## Pontos de atenção

- A classe do Thunar varia: já apareceu como `Thunar` e como `thunar` (iniciado por `thunar ~` no shell). A causa não foi confirmada; a suspeita é ativação D-Bus vs binário. Regra da Alice: toda windowrule do Thunar existe em DUAS linhas, uma com `^(Thunar)$` e outra com `^(thunar)$`. Ao criar ou mexer em uma, mexa nas duas; não junte em regex nem volte a uma grafia só.
- Histórico: a primeira versão pintava só `.thunar` por cima do Adwaita-dark, e diálogos/menus ficavam de fora. Por isso migrou para `adw-gtk3-dark` + cores nomeadas, que pega tudo.
- `~/.config/gtk-3.0` é link (via store) para `/etc/nixos/config/gtk-3.0`: editar o CSS vale na hora, mas o Thunar precisa de `thunar -q` para recarregar. O conteúdo NÃO fica na store, então mudança não commitada só existe no working tree.
- O Matugen pode regravar o `gtk.css`; se isso acontecer, a paleta some e precisa ser recolocada.
- Trocar tema ou ícones exige mudar três lugares: `gtk-theme.nix` e os dois `settings.ini`.
- Não testar atalhos do Thunar com `wtype` e modificadores: em 2026-11-14 um `wtype -M ctrl -M shift -k n` acabou disparando o bind `CTRL + SHIFT + ESCAPE` (`kitty systemctl poweroff -i`) e desligou a máquina.
- Fundos coloridos em algumas pastas (ex.: `.config`, `Downloads`) são o recurso de destaque do próprio Thunar, não o tema.
