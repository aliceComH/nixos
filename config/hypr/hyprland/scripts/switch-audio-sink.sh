#!/usr/bin/env bash

# 1. Pega a lista de sinks (nomes técnicos), excluindo o easyeffects
mapfile -t sinks < <(pactl list short sinks | awk '{print $2}' | grep -v "easyeffects")

# 2. Pega o sink padrão atual de forma limpa
current=$(pactl get-default-sink)

# 3. Descobre o índice do atual na nossa lista filtrada
index=-1
for i in "${!sinks[@]}"; do
    if [[ "${sinks[$i]}" == "$current" ]]; then
        index=$i
        break
    fi
done

# 4. O PULO DO GATO: Se não encontrar o atual na lista (ex: está no easyeffects), 
# ou se for o último da lista, o "next" deve ser 0 para fechar o loop.
if [ "$index" -eq -1 ] || [ "$index" -eq $(( ${#sinks[@]} - 1 )) ]; then
    next=0
else
    next=$(( index + 1 ))
fi

# 5. Define o novo sink como padrão
pactl set-default-sink "${sinks[$next]}"
