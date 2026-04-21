#!/usr/bin/env bash
# Volta a um workspace permitido ainda ativo, usando o histórico em ws_return_history
# (mantido por gaming_monitor.sh). Ignora 5/7/8 e IDs que não existem em hyprctl workspaces.
# Sem candidato válido: no-op (exit 0).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=workspace_nav.inc.sh
source "$SCRIPT_DIR/workspace_nav.inc.sh"

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  HYPRLAND_INSTANCE_SIGNATURE="$(ls -1 "$runtime_dir/hypr" 2>/dev/null | head -n1 || true)"
fi

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  exit 0
fi

WS_RETURN_HISTORY="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/ws_return_history"

command -v hyprctl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

FORBIDDEN_FILTER="$(forbidden_jq_filter)"
mapfile -t ACTIVE_PERMITTED < <(
  hyprctl workspaces -j | jq -r ".[] | select(.id > 0${FORBIDDEN_FILTER}) | .id" | sort -n -u
)

declare -A ACTIVE_SET
for id in "${ACTIVE_PERMITTED[@]}"; do
  ACTIVE_SET["$id"]=1
done

CURRENT_ID="$(hyprctl activeworkspace -j | jq -r '.id')"
if ! [[ "$CURRENT_ID" =~ ^-?[0-9]+$ ]]; then
  exit 0
fi

if [[ ! -f "$WS_RETURN_HISTORY" || ! -s "$WS_RETURN_HISTORY" ]]; then
  exit 0
fi

mapfile -t HIST < "$WS_RETURN_HISTORY"

chosen_idx=-1
target=""
for ((i = ${#HIST[@]} - 1; i >= 0; i--)); do
  id="${HIST[i]}"
  [[ ! "$id" =~ ^[0-9]+$ ]] && continue
  [[ "$id" -eq "$CURRENT_ID" ]] && continue
  if is_forbidden_ws "$id"; then
    continue
  fi
  if [[ -z "${ACTIVE_SET[$id]:-}" ]]; then
    continue
  fi
  chosen_idx="$i"
  target="$id"
  break
done

if [[ "$chosen_idx" -lt 0 || -z "$target" ]]; then
  exit 0
fi

tmp="${WS_RETURN_HISTORY}.tmp.$$"
if [[ "$chosen_idx" -gt 0 ]]; then
  for ((j = 0; j < chosen_idx; j++)); do
    printf '%s\n' "${HIST[j]}"
  done >"$tmp"
else
  : >"$tmp"
fi
mv -- "$tmp" "$WS_RETURN_HISTORY"

hyprctl dispatch workspace "$target"
