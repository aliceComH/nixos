#!/usr/bin/env bash
# adblock-killswitch.sh — Toggle on/off do bloqueio de anúncios DNS via unbound.
# Sem argumentos: detecta o estado atual e inverte (toggle).
# Com argumento:  'on' ativa, 'off' desativa.
# Uso: sudo /etc/nixos/config/hypr/hyprland/scripts/adblock-killswitch.sh [on|off]
set -euo pipefail

MASTER="/var/lib/unbound/adblock_master.conf"
ACTIVE="/var/lib/unbound/adblock.conf"

# ── Helpers ──────────────────────────────────────────────────────────────────
is_active() {
  [ -s "$ACTIVE" ]   # true se o arquivo existe E não está vazio
}

activate() {
  if [ ! -s "$MASTER" ]; then
    echo "[Erro]    Arquivo master vazio ou inexistente: $MASTER"
    echo "          Execute primeiro: sudo bash update-blocklist.sh"
    exit 1
  fi

  cp "$MASTER" "$ACTIVE"
  chown unbound:unbound "$ACTIVE"
  systemctl reload unbound

  local total
  total=$(wc -l < "$ACTIVE")
  echo "[Adblock] ✅ ATIVADO — $total domínios bloqueados."
}

deactivate() {
  truncate -s 0 "$ACTIVE"
  chown unbound:unbound "$ACTIVE"
  systemctl reload unbound

  echo "[Adblock] ❌ DESATIVADO — Nenhum domínio bloqueado."
}

# ── Main ─────────────────────────────────────────────────────────────────────
ACTION="${1:-toggle}"

case "$ACTION" in
  on)
    activate
    ;;
  off)
    deactivate
    ;;
  toggle)
    if is_active; then
      deactivate
    else
      activate
    fi
    ;;
  *)
    echo "Uso: $0 [on|off]"
    echo "  Sem argumentos: toggle automático"
    exit 1
    ;;
esac
