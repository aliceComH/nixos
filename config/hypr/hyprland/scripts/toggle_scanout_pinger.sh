#!/bin/bash

SCRIPT_NAME="scanout_pinger.sh"

if pgrep -f "/$SCRIPT_NAME$" > /dev/null; then
    pkill -f "/$SCRIPT_NAME$"
else
    ~/.config/hypr/hyprland/scripts/scanout_pinger.sh &
fi
