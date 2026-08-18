# Firefox + PWAsForFirefox

## O que é

Firefox é o browser padrão. Sites que antes abriam com
`google-chrome-stable --app=URL` passam pelo native host
[PWAsForFirefox](https://pwasforfirefox.filips.si/) (`firefoxpwa`): janela
própria, sem chrome de browser.

## Por que existe

O Chrome `--app` não existe no Firefox da mesma forma. O firefoxpwa instala
o site como PWA (runtime Firefox patched + extensão no Firefox desktop) e
o atalho só lança o ID. O Chrome permanece no sistema até a migração de
favoritos, mas já não é default nem está nos binds.

## Arquivos envolvidos

- `modules/home/firefox.nix` — `programs.firefox` + native messaging
  `firefoxpwa` + force-install da extensão `firefoxpwa@filips.si`; liga
  `user.js` / `userChrome.css` no perfil PWA partilhado e força
  `runtime_enable_wayland`. `media.volume_scale = 3` para o cubeb não
  espelhar loudness do YouTube na sink do PipeWire.
- `modules/nixos/services.nix` — `pulse.rules` `block-sink-volume` +
  `channelmix.lock-volumes` para `firefox` (as PWAs aparecem como
  `application.name=Firefox`).
- `config/firefoxpwa/user.js` + `userChrome.css` — esconde a icon/title
  bar (CSD GTK no Hyprland desenha botões fantasmas).
- `modules/home/session-variables.nix` — `BROWSER=firefox`.
- `modules/home/xdg-config.nix` — `mimeApps` http/https/html →
  `firefox.desktop`.
- `config/hypr/hyprland/scripts/launch-pwa.sh` — procura o PWA por host em
  `~/.local/share/firefoxpwa/config.json`; se não existir, `site install`
  e depois `site launch`.
- `config/hypr/hyprland/keybinds.lua` — ALT+R Firefox; ALT+2/4/6
  `launch-pwa.sh` (WhatsApp, Stremio, YouTube Music). Repetido nos submaps.
- `config/hypr/hyprland/windowrules/google-chrome.lua` — suppress maximize
  / sync fullscreen para `firefox` e Chrome (enquanto o Chrome existir).
- `config/hypr/hyprland/windowrules/workspace-9-whatsapp.lua` — WhatsApp e
  YouTube Music no workspace 9, pelo `class=FFPWA-<ulid>` (o título dinâmico
  não serve: WhatsApp vira "Mozilla Firefox").

## Depende de / Relacionado a

- **Fraco:** [mpv](mpv.md) — Stremio PWA pode acabar a abrir streams no
  umpv via MIME; não há acoplamento de config.

## Pontos de atenção

- A primeira vez que um atalho PWA corre, o `firefoxpwa` pode ter de
  instalar o runtime (`firefoxpwa runtime install`) e o próprio site;
  demora mais do que os lançamentos seguintes.
- O WM_CLASS das PWAs é `FFPWA-<ulid>`. As window rules do workspace 9
  casam pelo ulid (WhatsApp `01M05T5S6CXP43B4RVDNCPX6XC`, YouTube Music
  `01M05T56XMVRWSSVMYPTX6VM98`) e têm fallback por `initial_title`. O
  `title` actual não é fiável.
- Chrome continua em `modules/nixos/packages-system.nix` de propósito.
  O Firefox desktop vem de `programs.firefox` (home-manager), não do
  `environment.systemPackages`.
- A “barra de título” das PWAs **não** é decoração do Hyprland
  (`decorate = false` já está nos workspaces). É a icon bar CSD do
  firefoxpwa (`#titlebar` / `#TabsToolbar`). Pref `firefoxpwa.enableHidingIconBar`
  default é false; sem `userChrome.css` os botões nativos ficam fantasmas
  no tiling WM ([PWAsForFirefox#49](https://github.com/filips123/PWAsForFirefox/issues/49),
  [#742](https://github.com/filips123/PWAsForFirefox/issues/742)).
- `config.json` tem `runtime_enable_wayland` (o default do firefoxpwa é
  false → XWayland). O `launch-pwa.sh` volta a pôr true em cada lançamento
  porque o firefoxpwa pode repor o ficheiro. Fecha a janela com ALT+ESCAPE;
  a icon bar não volta com Ctrl+Alt (CSS força hide).
- Cubeb no Linux aplica `HTMLMediaElement.volume` como volume da
  sink-input ([bug 1422637](https://bugzilla.mozilla.org/show_bug.cgi?id=1422637)).
  YouTube/YT Music já fazem loudness no player; o mixer a 93–99% é esse
  valor a vazar. `media.volume_scale=3` satura em 100%; mute no player
  continua. As prefs do cubeb só entram no próximo arranque do processo.
