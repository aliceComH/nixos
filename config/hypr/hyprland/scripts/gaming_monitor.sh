#!/bin/bash

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
      # echo ">> Detectado: Entrando no submap gaming" >> "$LOG_FILE"
      hyprctl keyword render:direct_scanout true
      hyprctl dispatch submap gaming
    ;;

    "activespecial>>special:stash,HDMI-A-1")
      # echo ">> Detectado: Outro workspace especial, resetando submap" >> "$LOG_FILE"
      hyprctl keyword render:direct_scanout false
      hyprctl dispatch submap reset
    ;;

    "workspace>>"*)
      # echo ">> Detectado: Saindo do submap gaming" >> "$LOG_FILE"
      hyprctl keyword render:direct_scanout false
      hyprctl dispatch submap reset
    ;;

    "activespecial>>"*)
      # Forma mais robusta de pegar o que vem depois do >>
      data="${1#*>>}" 
      # Pega o que está antes da primeira vírgula
      special_name="${data%%,*}"

      if [[ -n "$special_name" ]]; then
        # Se o nome NÃO está vazio, você abriu um especial (stash, etc)
        hyprctl keyword render:direct_scanout false
        hyprctl dispatch submap reset
      else
        # Se o nome ESTÁ vazio, você fechou o especial e voltou pro workspace regular
        # Usamos -r no jq para vir texto limpo e [[ == ]] para comparar como string (mais seguro)
        current_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' 2>/dev/null)
        
        if [[ "$current_ws" == "5" ]]; then
          hyprctl keyword render:direct_scanout true
          hyprctl dispatch submap gaming
        else
          hyprctl keyword render:direct_scanout false
          hyprctl dispatch submap reset
        fi
      fi
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
