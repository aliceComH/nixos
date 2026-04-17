#!/usr/bin/env bash
#
# Mantém o HyperX QuadCast S cravado em -5dB (0.8254)
#

TARGET_VALUE="0.8254"
INTERVAL_SEC=2

trap 'exit 0' TERM INT

while true; do
    # wpctl é a forma mais moderna e estável de lidar com o PipeWire no Fedora 43
    wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$TARGET_VALUE" 2>/dev/null
    
    sleep "$INTERVAL_SEC"
done