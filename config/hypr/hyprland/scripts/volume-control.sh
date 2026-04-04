#!/bin/bash

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

# Toca o som de feedback padrão do sistema (ou você pode apontar para um .wav específico)
# O canberra-gtk-play é leve e não cria janelas
# canberra-gtk-play -i audio-volume-change -d "volume-change"
# pw-play ~/Downloads/lucadialessandro-shooting-sound-fx-159024.mp3
# pw-play ~/Downloads/freesound_community-low-tom-45416.mp3 