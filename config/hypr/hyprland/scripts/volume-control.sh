#!/usr/bin/env bash

set -euo pipefail

# Define o incremento
STEP="5%"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "volume-control: comando ausente: $1" >&2
    exit 1
  }
}

require_cmd wpctl
require_cmd awk
require_cmd sed

resolve_cloud3_sink_id() {
  local ids id inspect text
  ids="$(
    wpctl status | awk '
      /^Audio$/              { audio = 1; next }
      /^Video$/              { audio = 0; next }
      audio && /^ ├─ Sinks:$/ { ins = 1; next }
      audio && ins && /^ ├─ Sources:$/ { exit }
      ins && match($0, /│[[:space:]]+\*?[[:space:]]*([0-9]+)\./, a) { print a[1] }
    '
  )"

  for id in $ids; do
    inspect="$(wpctl inspect "$id" 2>/dev/null || true)"
    text="$(printf '%s\n' "$inspect" | sed -nE 's/^[[:space:]]*\*?[[:space:]]*(node\.(name|nick|description)) = "(.*)".*$/\3/p')"
    if printf '%s\n' "$text" | awk 'BEGIN{IGNORECASE=1} /cloud( iii)? wireless|cloud_iii_wireless/ { found=1 } END { exit !found }'; then
      echo "$id"
      return 0
    fi
  done

  return 1
}

target="${2:-default}"
sink_ref="@DEFAULT_AUDIO_SINK@"
if [[ "$target" == "cloud3" ]]; then
  cloud3_id="$(resolve_cloud3_sink_id || true)"
  if [[ -z "$cloud3_id" ]]; then
    echo "volume-control: não encontrei sink do HyperX Cloud III Wireless." >&2
    exit 1
  fi
  sink_ref="$cloud3_id"
fi

case $1 in
    up)
        wpctl set-volume --limit 1.0 "$sink_ref" "$STEP"+
        ;;
    down)
        wpctl set-volume --limit 1.0 "$sink_ref" "$STEP"-
        ;;
    mute)
        wpctl set-mute "$sink_ref" toggle
        ;;
esac
