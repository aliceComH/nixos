# shellcheck shell=bash
# Partilhado por cycle_workspaces.sh, gaming_monitor.sh e workspace_previous_filtered.sh
# Workspaces excluídos da navegação / histórico de retorno: 5 = gaming, 7 = stash, 8 = auxiliar
FORBIDDEN=(5 7 8)

is_forbidden_ws() {
  local id="$1"
  for f in "${FORBIDDEN[@]}"; do
    if [[ "$id" -eq "$f" ]]; then
      return 0
    fi
  done
  return 1
}

# Filtro jq: exclui IDs em FORBIDDEN (uso: select(.id > 0${FORBIDDEN_JQ_FILTER}))
forbidden_jq_filter() {
  printf ' and .id != %s' "${FORBIDDEN[@]}"
}
