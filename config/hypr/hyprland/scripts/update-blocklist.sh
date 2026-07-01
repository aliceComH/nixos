#!/usr/bin/env bash
# update-blocklist.sh — Baixa e converte a lista StevenBlack para sintaxe unbound.
# Grava o resultado em /var/lib/unbound/adblock_master.conf.
# Uso: sudo bash update-blocklist.sh
set -euo pipefail

HOSTS_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
MASTER_FILE="/var/lib/unbound/adblock_master.conf"
TMP_FILE=$(mktemp)

trap 'rm -f "$TMP_FILE"' EXIT

echo "[Update] Baixando blocklist StevenBlack..."
curl -fsSL "$HOSTS_URL" -o "$TMP_FILE"

echo "[Parse]  Convertendo para sintaxe unbound..."

# Filtra:
#   - Apenas linhas que começam com "0.0.0.0 " (bloqueio)
#   - Ignora 0.0.0.0 sozinho (a própria entrada do localhost)
#   - Remove comentários inline e espaços extras
#   - Converte para: local-zone: "dominio" always_nxdomain
count=$(
  grep -E '^0\.0\.0\.0\s+' "$TMP_FILE" \
    | awk '{print $2}' \
    | grep -vxE '0\.0\.0\.0|localhost|localhost\.localdomain|local' \
    | sort -u \
    | tee >(wc -l >&2) \
    | sed 's/.*/local-zone: "\0" always_nxdomain/' \
    > "$MASTER_FILE"
) 2>&1

TOTAL=$(wc -l < "$MASTER_FILE")
echo "[Pronto] $TOTAL domínios bloqueados gravados em $MASTER_FILE"

# Ajusta permissões para o unbound poder ler
chown unbound:unbound "$MASTER_FILE"
chmod 644 "$MASTER_FILE"

echo "[Info]   Execute 'sudo adblock-killswitch.sh' para ativar as regras."
