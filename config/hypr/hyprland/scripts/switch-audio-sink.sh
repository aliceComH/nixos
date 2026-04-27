#!/usr/bin/env bash
#
# Alterna o sink de áudio padrão (PipeWire + WirePlumber) via wpctl.
# Não usa pactl: no NixOS o binário pode não estar no PATH do Hyprland.
#

set -euo pipefail

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "switch-audio-sink: comando ausente: $1" >&2
    exit 1
  }
}

require_cmd wpctl
require_cmd awk
require_cmd sed

# Whitelist de sinks que podem virar default no ciclo.
# Cloud 3 não entra aqui de propósito: ele só recebe loopback quando 7.1 é default.
allowed_sink_patterns=(
  'HyperX 7\.1 Audio'
  'Kingston_HyperX_Virtual_Surround_Sound'
  'Navi .*HDMI'
  'alsa_output\..*hdmi'
)

# Lista IDs dos sinks na seção Audio.
mapfile -t sink_ids_all < <(
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

if [[ "${#sink_ids_all[@]}" -eq 0 ]]; then
  echo "switch-audio-sink: nenhum sink encontrado (wpctl status)." >&2
  exit 1
fi

sink_allowed() {
  local sink_name="$1"
  local pattern
  for pattern in "${allowed_sink_patterns[@]}"; do
    if [[ "$sink_name" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

sink_ids=()
for sink_id in "${sink_ids_all[@]}"; do
  sink_info="$(wpctl inspect "$sink_id" 2>/dev/null || true)"
  if [[ -z "$sink_info" ]]; then
    continue
  fi

  if printf '%s\n' "$sink_info" | awk 'BEGIN{IGNORECASE=1} /easy ?effects/ { found=1 } END { exit !found }'; then
    continue
  fi

  sink_nick="$(
    printf '%s\n' "$sink_info" | sed -nE 's/^[[:space:]]*\*?[[:space:]]*node\.nick = "([^"]+)".*$/\1/p' | head -n1
  )"
  sink_name="$(
    printf '%s\n' "$sink_info" | sed -nE 's/^[[:space:]]*\*?[[:space:]]*node\.name = "([^"]+)".*$/\1/p' | head -n1
  )"
  sink_match_text="$sink_nick $sink_name"

  if [[ -n "$sink_match_text" ]] && sink_allowed "$sink_match_text"; then
    sink_ids+=("$sink_id")
  fi
done

if [[ "${#sink_ids[@]}" -eq 0 ]]; then
  echo "switch-audio-sink: whitelist não encontrou sinks permitidos." >&2
  exit 1
fi

current_id="$(
  wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | head -1 | sed -nE 's/^id ([0-9]+),.*/\1/p' || true
)"
if [[ -z "$current_id" ]]; then
  echo "switch-audio-sink: não foi possível ler o sink atual (@DEFAULT_AUDIO_SINK@)." >&2
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

# Toda troca manual de sink default derruba o loopback HDMI.
if command -v mirror-audio >/dev/null 2>&1; then
  mirror-audio stop >/dev/null 2>&1 || true
  mirror-audio reconcile >/dev/null 2>&1 || true
fi
