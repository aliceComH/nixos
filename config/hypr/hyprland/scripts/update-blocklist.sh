#!/usr/bin/env bash
# update-blocklist.sh — Baixa as blocklists, junta, deduplica e converte para a
# sintaxe do unbound. Grava em /var/lib/unbound/adblock_master.conf e, se o
# bloqueio estiver ATIVO (adblock.conf não vazio), já aplica e recarrega.
#
# Roda sozinho toda semana (timer unbound-blocklist-update, em
# modules/nixos/local-dns.nix). Manual: sudo bash update-blocklist.sh
#
# Liberar um domínio bloqueado por engano: uma linha em
# /etc/nixos/config/unbound/allowlist.txt e rodar este script de novo.
set -euo pipefail

MASTER_FILE="/var/lib/unbound/adblock_master.conf"
ACTIVE_FILE="/var/lib/unbound/adblock.conf"
ALLOWLIST="/etc/nixos/config/unbound/allowlist.txt"

HAGEZI="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard"
# nome|url — todas em formato "um domínio por linha" ou hosts (0.0.0.0 dominio).
SOURCES=(
  "hagezi-pro++|$HAGEZI/pro.plus-onlydomains.txt"           # anúncios, trackers, telemetria (agressiva)
  "hagezi-tif-medium|$HAGEZI/tif.medium-onlydomains.txt"    # malware, phishing, golpes
  "hagezi-winoffice|$HAGEZI/native.winoffice-onlydomains.txt" # telemetria Windows/Office (jogos via Wine/Proton)
  "hagezi-tiktok|$HAGEZI/native.tiktok-onlydomains.txt"     # telemetria TikTok
  "stevenblack|https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
)

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Só passa o que tem cara de domínio. Isto também impede que uma lista
# comprometida injete diretivas no config do unbound.
DOMAIN_RE='^([a-z0-9_]([a-z0-9_-]{0,61}[a-z0-9_])?\.)+[a-z][a-z0-9-]{1,62}$'

extract() { # arquivo -> domínios, um por linha, minúsculos
  tr -d '\r' < "$1" \
    | sed -e 's/#.*//' -e 's/^[[:space:]]*\(0\.0\.0\.0\|127\.0\.0\.1\)[[:space:]]\+//' \
    | awk 'NF==1 {print tolower($1)}' \
    | grep -E "$DOMAIN_RE" || true
}

: > "$WORK/all"
for entry in "${SOURCES[@]}"; do
  name="${entry%%|*}"; url="${entry#*|}"
  if curl -fsSL --retry 3 --max-time 180 "$url" -o "$WORK/raw"; then
    extract "$WORK/raw" > "$WORK/one"
    n=$(wc -l < "$WORK/one")
    printf '[Lista]  %-18s %8d domínios\n' "$name" "$n"
    # Lista vazia = download quebrado; não deixar isso encolher o bloqueio.
    [[ "$n" -gt 0 ]] || { echo "[Erro]   $name veio vazia — abortando sem mexer em nada." >&2; exit 1; }
    cat "$WORK/one" >> "$WORK/all"
  else
    echo "[Erro]   Falha ao baixar $name — abortando sem mexer em nada." >&2
    exit 1
  fi
done

# Allowlist (opcional).
: > "$WORK/allow"
[[ -f "$ALLOWLIST" ]] && extract "$ALLOWLIST" | sort -u > "$WORK/allow"

# Deduplica e remove subdomínios já cobertos por um pai bloqueado
# (local-zone bloqueia o domínio E tudo abaixo dele). Chave = labels invertidos
# separados por espaço, para o pai ordenar imediatamente antes dos filhos.
LC_ALL=C sort -u "$WORK/all" \
  | grep -vxE 'localhost|localhost\.localdomain|local|broadcasthost' \
  | grep -vxFf "$WORK/allow" \
  | awk -F. '{k=$NF; for(i=NF-1;i>=1;i--) k=k" "$i; print k}' \
  | LC_ALL=C sort -u \
  | awk '{ if (p != "" && index($0, p " ") == 1) next; p=$0; n=split($0,a," "); d=a[n]; for(i=n-1;i>=1;i--) d=d"."a[i]; print d }' \
  > "$WORK/domains"

{
  # redirect + local-data: responde 0.0.0.0 / :: em vez de NXDOMAIN. Sites que
  # tratam NXDOMAIN como erro fatal (layout/JS quebrados) passam a receber um
  # endereço nulo e falham de forma limpa. `redirect` exige local-data no apex.
  awk '{
    print "local-zone: \"" $0 ".\" redirect"
    print "local-data: \"" $0 ". A 0.0.0.0\""
    print "local-data: \"" $0 ". AAAA ::\""
  }' "$WORK/domains"
  # Liberados: zona mais específica vence o pai bloqueado.
  sed 's/.*/local-zone: "&." always_transparent/' "$WORK/allow"
} > "$WORK/master"

TOTAL=$(wc -l < "$WORK/domains")
echo "[Pronto] $TOTAL domínios únicos ($(wc -l < "$WORK/all") antes de deduplicar), $(wc -l < "$WORK/allow") liberados."

# Valida num config mínimo antes de trocar o arquivo em uso.
printf 'server:\n  chroot: ""\n  username: ""\n  include: "%s"\n' "$WORK/master" > "$WORK/check.conf"
unbound-checkconf "$WORK/check.conf" >/dev/null || { echo "[Erro]   unbound-checkconf rejeitou a lista — nada foi trocado." >&2; exit 1; }

install -o unbound -g unbound -m 644 "$WORK/master" "$MASTER_FILE"

if [[ -s "$ACTIVE_FILE" ]]; then
  install -o unbound -g unbound -m 644 "$WORK/master" "$ACTIVE_FILE"
  systemctl reload unbound
  echo "[Adblock] ATIVO — lista nova aplicada."
else
  echo "[Info]   Bloqueio está desligado; lista nova fica pronta em $MASTER_FILE."
  echo "         Ative com: sudo /etc/nixos/config/hypr/hyprland/scripts/adblock-killswitch.sh on"
fi
