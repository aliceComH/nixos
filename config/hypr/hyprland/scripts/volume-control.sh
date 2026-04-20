#!/usr/bin/env bash

# Define o incremento
STEP="5%"

case $1 in
    up)
        wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ "$STEP"+
        ;;
    down)
        wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ "$STEP"-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
esac
