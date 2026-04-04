#!/bin/bash

# Intervalo em segundos entre cada verificação
INTERVAL=1

echo "Monitorando Direct Scanout via IPC... (Pressione Ctrl+C para parar)"

while true; do
    # 1. Pega o valor de directScanoutTo do monitor focado
    # Usamos o '.[0]' assumindo que você está na TV 4K, ou buscamos o 'focused'
    SCANOUT_ADDR=$(hyprctl -j monitors | jq -r '.[] | select(.focused == true) | .directScanoutTo')

    # 2. Verifica se o endereço é diferente de 0 (ou "null" caso a versão mude)
    if [[ "$SCANOUT_ADDR" != "0" && "$SCANOUT_ADDR" != "null" ]]; then
        # Toca o som conforme solicitado
        canberra-gtk-play -i audio-volume-change -d "volume-change" &
        
        # Opcional: Mostra no terminal para você ver o endereço da janela
        # echo -e "\e[32m[SCANOUT ATIVO]\e[0m Janela: $SCANOUT_ADDR"
    fi

    sleep $INTERVAL
done
