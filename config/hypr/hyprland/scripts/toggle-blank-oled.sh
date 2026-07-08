#!/usr/bin/env bash

# Nome identificador para a regra de janela e para o pkill
APP_ID="blank-oled"

# Verifica se já existe um imv rodando com este ID
if pkill -f "imv.*-i $APP_ID"; then
    echo "Monitor OLED ativado (imv fechado)."
else
    echo "Apagando monitor OLED..."
    # Lança o imv com uma imagem preta e fundo preto, forçando a resolução do monitor
    imv -W 2560 -H 1440 -s crop -i "$APP_ID" -b 000000 /etc/nixos/config/hypr/hyprland/scripts/black.png &
fi
