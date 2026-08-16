#!/usr/bin/env bash
# Instala (se preciso) e lança um PWA via firefoxpwa (PWAsForFirefox).
# Uso: launch-pwa.sh <url> [nome]
set -euo pipefail

URL="${1:?uso: launch-pwa.sh <url> [nome]}"
NAME="${2:-}"
CONFIG="${XDG_DATA_HOME:-$HOME/.local/share}/firefoxpwa/config.json"

host_of() {
  local u="${1#*://}"
  echo "${u%%/*}" | tr '[:upper:]' '[:lower:]'
}

origin_of() {
  local u="$1"
  local scheme host
  scheme="${u%%://*}"
  host="$(host_of "$u")"
  echo "${scheme}://${host}"
}

WANT_HOST="$(host_of "$URL")"
ORIGIN="$(origin_of "$URL")"

find_id() {
  [[ -f "$CONFIG" ]] || return 1
  jq -r --arg host "$WANT_HOST" '
    (.sites // {}) | to_entries[]
    | select(
        ((.value.config.document_url // "") | ascii_downcase | contains($host))
        or ((.value.config.manifest_url // "") | ascii_downcase | contains($host))
      )
    | .key
  ' "$CONFIG" | head -n1
}

# firefoxpwa site install exige a URL do *manifest*, não a da página.
resolve_manifest() {
  python3 - "$URL" "$ORIGIN" <<'PY'
import re, sys, urllib.request

url, origin = sys.argv[1], sys.argv[2]
req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
html = ""
try:
    with urllib.request.urlopen(req, timeout=12) as resp:
        html = resp.read().decode("utf-8", "ignore")
except Exception:
    pass

href = ""
m = re.search(
    r"""<link[^>]+rel=["']manifest["'][^>]*href=["']([^"']+)["']""",
    html,
    re.I,
)
if not m:
    m = re.search(
        r"""<link[^>]+href=["']([^"']+)["'][^>]*rel=["']manifest["']""",
        html,
        re.I,
    )
if m:
    href = m.group(1)

if href.startswith("http://") or href.startswith("https://"):
    print(href)
    sys.exit(0)
if href.startswith("/"):
    print(origin + href)
    sys.exit(0)
if href:
    print(origin + "/" + href)
    sys.exit(0)

for cand in (origin + "/manifest.webmanifest", origin + "/manifest.json"):
    try:
        urllib.request.urlopen(
            urllib.request.Request(cand, headers={"User-Agent": "Mozilla/5.0"}),
            timeout=8,
        )
        print(cand)
        sys.exit(0)
    except Exception:
        continue
sys.exit(1)
PY
}

ensure_runtime() {
  local runtime="${XDG_DATA_HOME:-$HOME/.local/share}/firefoxpwa/runtime"
  if [[ ! -e "$runtime/firefox" && ! -e "$runtime/librewolf" ]]; then
    firefoxpwa runtime install || true
  fi
}

# Icon bar CSD do firefoxpwa no Hyprland: esconder + Wayland nativo.
# O perfil partilhado é sempre o ulid de zeros; o firefoxpwa pode repor
# runtime_enable_wayland=false e o xulstore ao patchar o runtime.
prepare_chrome() {
  local data="${XDG_DATA_HOME:-$HOME/.local/share}/firefoxpwa"
  local profile="$data/profiles/00000000000000000000000000"
  local repo="/etc/nixos/config/firefoxpwa"
  mkdir -p "$profile/chrome"
  if [[ -f "$repo/user.js" ]]; then
    ln -sfn "$repo/user.js" "$profile/user.js"
  fi
  if [[ -f "$repo/userChrome.css" ]]; then
    ln -sfn "$repo/userChrome.css" "$profile/chrome/userChrome.css"
  fi
  if [[ -f "$CONFIG" ]]; then
    local tmp
    tmp="$(mktemp)"
    jq '.config.runtime_enable_wayland = true' "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
  fi
  local xul="$profile/xulstore.json"
  if [[ -f "$xul" ]]; then
    local tmp
    tmp="$(mktemp)"
    jq '.["chrome://browser/content/browser.xhtml"].TabsToolbar.collapsed = "true"' \
      "$xul" > "$tmp" && mv "$tmp" "$xul"
  fi
}

prepare_chrome

ID="$(find_id || true)"
if [[ -n "$ID" ]]; then
  exec firefoxpwa site launch "$ID"
fi

ensure_runtime
MANIFEST="$(resolve_manifest || true)"
if [[ -z "$MANIFEST" ]]; then
  echo "launch-pwa: não achei manifest.webmanifest/json em $URL" >&2
  exit 1
fi

extra=(--document-url "$URL" --launch-now)
[[ -n "$NAME" ]] && extra+=(--name "$NAME")
exec firefoxpwa site install "${extra[@]}" "$MANIFEST"
