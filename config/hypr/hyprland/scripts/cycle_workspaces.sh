#!/usr/bin/env bash

set -euo pipefail

# Configuracao
DIRECTION="${1:-next}" # "next" ou "prev"
# Workspaces excluidos da navegacao por alt-tab: 5 = gaming, 7 = stash, 8 = auxiliar
FORBIDDEN=(5 7 8)

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

# Monta o filtro jq dinamicamente a partir do array FORBIDDEN
FORBIDDEN_FILTER="$(printf ' and .id != %s' "${FORBIDDEN[@]}")"

# 1. Pega os IDs dos workspaces numericos ativos, exclui os proibidos e ordena.
mapfile -t WS_IDS < <(
  hyprctl workspaces -j | jq -r ".[] | select(.id > 0${FORBIDDEN_FILTER}) | .id" | sort -n
)

# 2. Pega o ID do workspace atual.
CURRENT_ID="$(hyprctl activeworkspace -j | jq -r '.id')"

if ! [[ "$CURRENT_ID" =~ ^-?[0-9]+$ ]]; then
  exit 1
fi

# 3. Se estivermos num workspace proibido, pula para o 1 e encerra.
is_forbidden=false
for f in "${FORBIDDEN[@]}"; do
  if [[ "$CURRENT_ID" -eq "$f" ]]; then
    is_forbidden=true
    break
  fi
done
if $is_forbidden; then
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
