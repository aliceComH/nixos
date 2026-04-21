#!/usr/bin/env bash
# Escolhe o primeiro ficheiro (ordenado com LC_ALL=C) em <repo>/wallpapers e
# atualiza o symlink ~/.local/state/nixos-wallpaper/current para o caminho absoluto.
# O hyprpaper lê o symlink em ~/.config/hypr/hyprpaper.conf ao arrancar (exec-once).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# config/hypr/hyprland/scripts -> ../../../.. = raiz do repositório (ex. /etc/nixos)
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
WALLPAPER_DIR="$REPO_ROOT/wallpapers"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-wallpaper"
CURRENT_LINK="$STATE_DIR/current"

if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "set_wallpaper: pasta inexistente: $WALLPAPER_DIR" >&2
  exit 1
fi

mapfile -t files < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f 2>/dev/null | LC_ALL=C sort || true)
if [[ "${#files[@]}" -eq 0 ]]; then
  echo "set_wallpaper: nenhum ficheiro em $WALLPAPER_DIR" >&2
  exit 1
fi

first="${files[0]}"
first_abs="$(readlink -f "$first")"

mkdir -p "$STATE_DIR"
ln -sfn "$first_abs" "$CURRENT_LINK"
