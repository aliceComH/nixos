#!/usr/bin/env bash

# Opcional: Log para debugar (pode comentar depois)
# LOG_FILE="/tmp/gaming_monitor.log"

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  HYPRLAND_INSTANCE_SIGNATURE="$(ls -1 "$runtime_dir/hypr" 2>/dev/null | head -n1 || true)"
fi

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  notify-send "Hyprland" "gaming_monitor: HYPRLAND_INSTANCE_SIGNATURE ausente"
  exit 1
fi

# touch "$HOME/.config/hypr/hyprland/scripts/submap_handler.log"
# LAST_SUBMAP="$HOME/.config/hypr/hyprland/scripts/submap_handler.log"
# echo "reset" > "$LAST_SUBMAP"

handle() {
  # echo "$1" >> "$LOG_FILE"

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

# Conecta ao socket e processa os eventos
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do 
    handle "$line"
done

# pkill -f "/gaming_monitor.sh$"
