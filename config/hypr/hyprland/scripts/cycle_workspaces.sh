#!/bin/bash

# Configuração
DIRECTION=$1 # "next" ou "prev"
FORBIDDEN=5

# 1. Pega os IDs dos workspaces numéricos ativos, exclui o 5 e ordena
WS_IDS=($(hyprctl workspaces -j | jq -r ".[] | select(.id > 0 and .id != $FORBIDDEN) | .id" | sort -n))

# 2. Pega o ID do workspace atual
CURRENT_ID=$(hyprctl activeworkspace -j | jq -r '.id')

# 3. Se por acaso estivermos no 5, pula para o 1 e encerra
if [ "$CURRENT_ID" -eq "$FORBIDDEN" ]; then
    hyprctl dispatch workspace 1
    exit 0
fi

# 4. Encontra o índice do workspace atual no nosso array
CUR_IDX=-1
for i in "${!WS_IDS[@]}"; do
   if [[ "${WS_IDS[$i]}" -eq "${CURRENT_ID}" ]]; then
       CUR_IDX=$i
       break
   fi
done

# 5. Se o workspace atual não estiver no array (ex: workspace vazio recém-criado)
# a gente volta para o ID 1 para resetar o fluxo
if [ "$CUR_IDX" -eq -1 ]; then
    hyprctl dispatch workspace 1
    exit 0
fi

# 6. Heurística de Loop (Wrap-around)
NUM_WS=${#WS_IDS[@]}
if [ "$DIRECTION" == "next" ]; then
    NEXT_IDX=$(( (CUR_IDX + 1) % NUM_WS ))
else
    NEXT_IDX=$(( (CUR_IDX - 1 + NUM_WS) % NUM_WS ))
fi

TARGET_ID=${WS_IDS[$NEXT_IDX]}

# 7. Executa o pulo
hyprctl dispatch workspace "$TARGET_ID"
