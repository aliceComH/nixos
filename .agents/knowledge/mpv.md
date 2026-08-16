# mpv

## O que é

Player de vídeo usado como instância única no sistema, com interpolação de
frames via VapourSynth/RIFE, tradução ao vivo de legendas e integração com
um pipeline de streaming (Crunchyroll via OBS).

## Por que existe

O mpv substitui players padrão para permitir interpolação de frames
(120fps via RIFE/GPU ou MVTools/CPU) e automações específicas (tradução de
legenda ao vivo, busca de legenda, instância única). Roda sempre no
workspace 8 (auxiliar), separado do fluxo principal de trabalho.

## Arquivos envolvidos

- `modules/nixos/packages-system.nix` — build do pacote: wrapper
  `mpv-single-instance` mata qualquer instância anterior via `pkill` antes
  de abrir uma nova (`--run 'for p in $(pgrep -x mpv)...'`) e injeta
  LuaSocket no `LUA_PATH`/`LUA_CPATH` (necessário pelo `translate-sub.lua`).
  `mpv-unwrapped` é compilado com VapourSynth + `vapoursynth-mvtools` +
  plugin RIFE customizado (`pkgs/vapoursynth-rife-ncnn-vulkan/package.nix`).
- `modules/home/xdg-config.nix` — symlink `config/mpv` → `~/.config/mpv`;
  desktop entry `mpv-stremio` (`exec = "mpv-stremio-cleaner %U"`) ainda
  existe, mas o `mimeApps` aponta áudio/vídeo (incluindo `.m3u`/`.m3u8`)
  para `umpv.desktop` e imagens para `imv-dir.desktop`.
- `config/mpv/mpv.conf` — base (`video-sync=display-resample`,
  `keep-open=yes`) + dois perfis de interpolação:
  - `[interp-rife]` — GPU/Vulkan, filtro `~/.config/mpv/filters/interpolation-rife.vpy`.
  - `[interp-vector]` — CPU (MVTools), filtro
    `~/.config/mpv/filters/interpolation.vpy`, estilo SVP.
- `config/mpv/scripts/delay-interp.lua` — espera 3s após carregar o arquivo
  e só aplica o perfil `interp-vector` se houver faixa de vídeo (evita
  crash no primeiro frame do VapourSynth a 120fps; áudio puro não ativa
  interpolação).
- `config/mpv/scripts/translate-sub.lua` — overlay de tradução ao vivo
  (`ass-events`) via LuaSocket, `POST http://localhost:5000/translate`.
  Atalho `Ctrl+T` liga/desliga.
- `config/mpv/scripts/busca-legenda.lua` — atalho `Ctrl+F` monta URL de
  busca no OpenSubtitles a partir do `media-title` (título costuma vir
  "limpo" quando o arquivo chega via Stremio/M3U) e abre via `xdg-open`.
- `config/hypr/hyprland/windowrules/workspace-8-auxiliar.lua` — janelas
  `class=mpv` vão para o workspace 8.
- `config/hypr/hyprland/windowrules/workspace-7-stash.lua` — Firefox vai
  para o workspace 7 (fonte de captura do OBS no pipeline de streaming
  abaixo).
- `config/hypr/hyprland/general.lua` — `misc.swallow_regex` inclui `mpv`
  (terminal que abre o mpv via CLI é "engolido").
- `modules/nixos/crunchyroll-mpv.nix` — comando `media-stream`: cria sink
  nula `Crunchyroll-Sink` (reusa se já existir), sobe OBS em background,
  espera o WebSocket (porta 4455), inicia gravação via `obs-cmd`, e abre
  `mpv udp://127.0.0.1:1234` — herda os perfis de interpolação do
  `mpv.conf` normalmente.

## Depende de / Relacionado a

- **Forte:** LibreTranslate (`modules/nixos/libretranslate.nix`, container
  Docker na porta 5000, modelos `en`/`pb`) — `translate-sub.lua` não
  funciona sem esse container rodando.
- **Fraco:** Stremio (flatpak em `modules/home/flatpak-user.nix`) — Stremio
  só invoca o mpv como player de destino; não há acoplamento de
  configuração entre os dois. Abertura de ficheiros de mídia no file
  manager vai para `umpv`, não para o entry `mpv-stremio`.

## Pontos de atenção

- **Comando quebrado:** `xdg-config.nix` define o desktop entry
  `mpv-stremio` com `exec = "mpv-stremio-cleaner %U"`, mas esse comando
  **não existe em nenhum lugar do repositório** (não há
  `writeShellScriptBin` nem script correspondente). Qualquer arquivo M3U
  aberto via esse entry vai falhar silenciosamente até esse script ser
  criado ou o entry ser corrigido para apontar para o `mpv` puro.
- **Comentário desatualizado:** `config/hypr/hyprland/windowrules/floating.lua`
  tem uma seção "Monitor Blanking (Software via MPV)" com regras para
  `blank-oled`/`blank-tv`, mas os scripts reais
  (`config/hypr/hyprland/scripts/toggle-blank-oled.sh` e `toggle-blank-tv.sh`)
  usam `imv` (visualizador de imagem), não mpv. Não é uma dependência real
  do mpv — só o comentário ficou desatualizado.
- Instância única é forçada via `pkill -9` no wrapper; abrir dois vídeos
  rapidamente em sequência mata o primeiro processo antes dele terminar de
  fechar sozinho.
- `translate-sub.lua` usa LuaSocket em vez de `subprocess`/fork
  deliberadamente — fork() no mpv trava a GPU em AMDGPU + Vulkan.
