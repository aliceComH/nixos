# Wallpapers

Coloca aqui **`1.jpeg`** (nome fixo). O script [`config/hypr/hyprland/scripts/set_wallpaper.sh`](../config/hypr/hyprland/scripts/set_wallpaper.sh) usa só esse ficheiro e actualiza `~/.local/state/nixos-wallpaper/` (symlink `current` + `hyprpaper.conf`).

O caminho da pasta vem da raiz do repositório (via `pwd -P` a partir de `~/.config/hypr`); o fluxo normal do NixOS é o clone em **`/etc/nixos`** — vê o [README.md](../README.md) na raiz.
