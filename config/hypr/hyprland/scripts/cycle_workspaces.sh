#!/usr/bin/env bash

set -euo pipefail

# Configuracao
DIRECTION="${1:-next}" # "next" ou "prev"
FORBIDDEN=5

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    exit 1
  }
}

require_cmd hyprctl
require_cmd jq

if [[ "$DIRECTION" != "next" && "$DIRECTION" != "prev" ]]; then
  exit 1
fi

# 1. Pega os IDs dos workspaces numericos ativos, exclui o 5 e ordena.
mapfile -t WS_IDS < <(
  hyprctl workspaces -j | jq -r ".[] | select(.id > 0 and .id != $FORBIDDEN) | .id" | sort -n
)

# 2. Pega o ID do workspace atual.
CURRENT_ID="$(hyprctl activeworkspace -j | jq -r '.id')"

if ! [[ "$CURRENT_ID" =~ ^-?[0-9]+$ ]]; then
  exit 1
fi

# 3. Se estivermos no 5, pula para o 1 e encerra.
if [[ "$CURRENT_ID" -eq "$FORBIDDEN" ]]; then
  hyprctl dispatch workspace 1
  exit 0
fi

# Se nao houver workspaces navegaveis, volta para 1.
if [[ "${#WS_IDS[@]}" -eq 0 ]]; then
  hyprctl dispatch workspace 1
  exit 0
fi

# 4. Encontra o indice do workspace atual no array.
CUR_IDX=-1
for i in "${!WS_IDS[@]}"; do
  if [[ "${WS_IDS[$i]}" -eq "${CURRENT_ID}" ]]; then
    CUR_IDX="$i"
    break
  fi
done

# 5. Se o workspace atual nao estiver no array, volta para 1.
if [[ "$CUR_IDX" -eq -1 ]]; then
  hyprctl dispatch workspace 1
  exit 0
fi

# 6. Heuristica de loop (wrap-around).
NUM_WS="${#WS_IDS[@]}"
if [[ "$DIRECTION" == "next" ]]; then
  NEXT_IDX="$(( (CUR_IDX + 1) % NUM_WS ))"
else
  NEXT_IDX="$(( (CUR_IDX - 1 + NUM_WS) % NUM_WS ))"
fi

TARGET_ID="${WS_IDS[$NEXT_IDX]}"

# 7. Executa o pulo.
hyprctl dispatch workspace "$TARGET_ID"
