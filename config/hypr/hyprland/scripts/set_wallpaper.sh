#!/usr/bin/env bash
# Usa só wallpapers/1.jpeg na raiz do repo.
# Atualiza ~/.local/state/nixos-wallpaper/current (Rofi, etc.) e gera hyprpaper.conf (hyprlang 0.8+).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd -P)"
WALLPAPER_FILE="$REPO_ROOT/wallpapers/1.jpeg"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-wallpaper"
CURRENT_LINK="$STATE_DIR/current"
HYPRPAPER_CONF="$STATE_DIR/hyprpaper.conf"

if [[ ! -f "$WALLPAPER_FILE" ]]; then
  echo "set_wallpaper: falta $WALLPAPER_FILE (coloca a imagem com este nome exacto)." >&2
  exit 1
fi

first_abs="$(readlink -f "$WALLPAPER_FILE")"
if [[ ! -f "$first_abs" ]]; then
  echo "set_wallpaper: caminho inválido: $WALLPAPER_FILE" >&2
  exit 1
fi

mkdir -p "$STATE_DIR"
ln -sfn "$first_abs" "$CURRENT_LINK"

mons=()
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  mapfile -t mons < <(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null || true)
fi

tmp="${HYPRPAPER_CONF}.tmp.$$"
{
  printf '# Gerado por set_wallpaper.sh\n'
  printf 'splash = false\n'
  if [[ "${#mons[@]}" -gt 0 ]]; then
    for mon in "${mons[@]}"; do
      [[ -z "$mon" ]] && continue
      printf 'wallpaper {\n'
      printf '    monitor = %s\n' "$mon"
      printf '    path = %s\n' "$first_abs"
      printf '    fit_mode = cover\n'
      printf '}\n'
    done
  else
    printf 'wallpaper {\n'
    printf '    monitor = *\n'
    printf '    path = %s\n' "$first_abs"
    printf '    fit_mode = cover\n'
    printf '}\n'
  fi
} >"$tmp"
mv -- "$tmp" "$HYPRPAPER_CONF"
