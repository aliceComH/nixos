#!/usr/bin/env bash

# Opcional: Log para debugar (pode comentar depois)
# LOG_FILE="/tmp/gaming_monitor.log"

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  HYPRLAND_INSTANCE_SIGNATURE="$(ls -1 "$runtime_dir/hypr" 2>/dev/null | head -n1 || true)"
fi

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  echo "gaming_monitor: HYPRLAND_INSTANCE_SIGNATURE ausente" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=workspace_nav.inc.sh
source "$SCRIPT_DIR/workspace_nav.inc.sh"

WS_RETURN_HISTORY="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/ws_return_history"

append_allowed_id_dedupe() {
  local id="$1" f="$WS_RETURN_HISTORY"
  local last=""
  [[ -f "$f" && -s "$f" ]] && last="$(tail -n1 "$f" 2>/dev/null || true)"
  [[ "$last" == "$id" ]] && return 0
  local tmp="${f}.tmp.$$"
  if [[ -f "$f" && -s "$f" ]]; then
    cp -- "$f" "$tmp"
  else
    : >"$tmp"
  fi
  printf '%s\n' "$id" >>"$tmp"
  mv -- "$tmp" "$f"
}

reset_history_to_id() {
  local id="$1" f="$WS_RETURN_HISTORY"
  mkdir -p "$(dirname "$f")"
  local tmp="${f}.tmp.$$"
  printf '%s\n' "$id" >"$tmp"
  mv -- "$tmp" "$f"
}

# Atualiza ficheiro de histórico (só IDs permitidos) conforme transição prev -> n.
update_ws_return_history() {
  local prev="$1" n="$2"
  local f="$WS_RETURN_HISTORY"

  if is_forbidden_ws "$n"; then
    return 0
  fi

  local prev_num=0 prev_forb=0
  if [[ "$prev" =~ ^[0-9]+$ ]]; then
    prev_num=1
    if is_forbidden_ws "$prev"; then
      prev_forb=1
    fi
  fi

  if [[ "$prev_num" -eq 0 ]] || [[ "$prev_forb" -eq 1 ]]; then
    reset_history_to_id "$n"
    return 0
  fi

  append_allowed_id_dedupe "$n"
}

PREV_WS=""

handle() {
  # echo "$1" >> "$LOG_FILE"

  if [[ "$1" == workspace\>\>* ]]; then
    local rest="${1#workspace>>}"
    if [[ "$rest" =~ ^[0-9]+$ ]]; then
      update_ws_return_history "${PREV_WS:-}" "$rest"
      PREV_WS="$rest"
    fi
  fi

  case "$1" in
    "workspace>>5")
      hyprctl keyword render:direct_scanout true
      hyprctl dispatch submap gaming
    ;;

    "workspace>>8")
      hyprctl keyword render:direct_scanout false
      hyprctl dispatch submap auxiliar
    ;;

    "workspace>>"*)
      hyprctl keyword render:direct_scanout false
      hyprctl dispatch submap reset
    ;;
  esac
}

# Espera o Hyprland estabilizar o socket no boot
sleep 2

# Process substitution mantém PREV_WS entre iterações (evita subshell do pipe).
while IFS= read -r line; do
  handle "$line"
done < <(socat -U - "UNIX-CONNECT:${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock")

# pkill -f "/gaming_monitor.sh$"
