#!/usr/bin/env bash
#
# Alterna o sink de áudio padrão (PipeWire + WirePlumber) via wpctl.
# Não usa pactl: no NixOS o binário pode não estar no PATH do Hyprland.
#

set -euo pipefail

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    notify-send "Áudio" "Comando ausente: $1" || true
    exit 1
  }
}

require_cmd wpctl
require_cmd awk

# IDs dos sinks na secção Audio (exclui linhas com easyeffects no texto).
mapfile -t sink_ids < <(
  wpctl status | awk '
    /^Audio$/              { audio = 1; next }
    /^Video$/              { audio = 0; next }
    audio && /^ ├─ Sinks:$/ { ins = 1; next }
    audio && ins && /^ ├─ Sources:$/ { exit }
    ins && match($0, /│[[:space:]]+\*?[[:space:]]*([0-9]+)\./, a) {
      line = tolower($0)
      if (line !~ /easyeffects/) print a[1]
    }
  '
)

if [[ "${#sink_ids[@]}" -eq 0 ]]; then
  notify-send "Áudio" "Nenhum sink encontrado (wpctl status)." || true
  exit 1
fi

current_id="$(
  wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | head -1 | sed -nE 's/^id ([0-9]+),.*/\1/p' || true
)"
if [[ -z "$current_id" ]]; then
  notify-send "Áudio" "Não foi possível ler o sink atual (@DEFAULT_AUDIO_SINK@)." || true
  exit 1
fi

index=-1
for i in "${!sink_ids[@]}"; do
  if [[ "${sink_ids[$i]}" == "$current_id" ]]; then
    index=$i
    break
  fi
done

# Se o atual não está na lista (ex.: filtro) ou é o último, volta ao primeiro.
if [[ "$index" -eq -1 ]] || [[ "$index" -eq $((${#sink_ids[@]} - 1)) ]]; then
  next=0
else
  next=$((index + 1))
fi

next_id="${sink_ids[$next]}"
wpctl set-default "$next_id"
notify-send "Áudio" "Sink padrão: id $next_id" || true
