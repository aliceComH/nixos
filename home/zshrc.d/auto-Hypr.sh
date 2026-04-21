# Auto start Hyprland on tty1 (usa start-hyprland: evita o aviso "started without start-hyprland").
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  mkdir -p ~/.cache
  exec start-hyprland > ~/.cache/hyprland.log 2>&1
fi
