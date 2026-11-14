#!/usr/bin/env bash
# Atualiza UM grupo do sistema. Chamado pela Central de Updates (updates.py),
# mas funciona sozinho: update-group.sh <hyprland|osu|sistema|programas>
#
# Fluxo: atualiza os inputs do grupo -> build -> mostra o diff de versões ->
# pergunta -> só então aplica (nixos-rebuild switch). Se você recusar ou algo
# falhar, flake.nix e flake.lock voltam ao estado anterior.
#
# FONTE DA VERDADE do mapeamento grupo -> inputs. Se mudar aqui, mude também
# GROUPS em updates.py e o comentário no topo de flake.nix.
set -euo pipefail

FLAKE=/etc/nixos
HOST=alice-nixos
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/central-updates"

group="${1:-}"
case "$group" in
  hyprland)  inputs=(nixpkgs-hyprland) ;;
  osu)       inputs=(nixpkgs-osu) ;;
  sistema)   inputs=(nixpkgs home-manager) ;;
  programas) inputs=(nixpkgs-apps antigravity-nix claude-desktop bedrock-on-linux) ;;
  *) echo "uso: $0 <hyprland|osu|sistema|programas>" >&2; exit 2 ;;
esac

bold() { printf '\n\033[1;35m== %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m%s\033[0m\n' "$*"; }
ask()  { local a; read -r -p "$1 [s/N] " a; [[ "$a" =~ ^[sS]$ ]]; }

mkdir -p "$WORK"
backup="$(mktemp -d)"
cp "$FLAKE/flake.lock" "$FLAKE/flake.nix" "$backup/"
applied=0

restore() {
  if [[ "$applied" -eq 0 ]]; then
    cp "$backup/flake.lock" "$backup/flake.nix" "$FLAKE/"
    warn "flake.nix e flake.lock restaurados — nada mudou no sistema."
  fi
}
finish() {
  local code=$?
  [[ $code -ne 0 ]] && restore
  rm -rf "$backup"
  echo
  read -r -p "Enter para fechar..." _ || true
  exit $code
}
trap finish EXIT

cd "$FLAKE"

# ── 1. Atualizar os inputs do grupo ─────────────────────────────────────────
if [[ "$group" == hyprland ]]; then
  # O Hyprland é travado por rev na URL do input; atualizar = trocar a rev.
  current="$(sed -n 's|.*nixpkgs-hyprland.url = "github:NixOS/nixpkgs/\([0-9a-f]\{40\}\)".*|\1|p' flake.nix)"
  [[ -n "$current" ]] || { echo "Não achei a rev do nixpkgs-hyprland em flake.nix." >&2; exit 1; }

  bold "Consultando o Hyprland do nixos-unstable"
  latest="$(nix flake metadata github:NixOS/nixpkgs/nixos-unstable --json | jq -r .locked.rev)"
  cur_ver="$(nix eval --raw "github:NixOS/nixpkgs/$current#hyprland.version")"
  new_ver="$(nix eval --raw "github:NixOS/nixpkgs/$latest#hyprland.version")"
  echo "Travado hoje: $cur_ver  (nixpkgs ${current:0:8})"
  echo "Disponível:   $new_ver  (nixpkgs ${latest:0:8})"

  if [[ "$cur_ver" == "$new_ver" ]]; then
    echo "O Hyprland já está na versão mais recente do nixos-unstable."
    exit 0
  fi

  echo
  warn "ATENÇÃO: o Hyprland está travado na $cur_ver de propósito."
  warn "A wiki e o código-fonte locais (wiki-hyprland-*, source-code-hyprland-*),"
  warn "o CLAUDE.md e .agents/rules/hyprland-guidelines.md são todos da $cur_ver."
  warn "A config em Lua (config/hypr/) pode quebrar com a $new_ver."
  ask "Trocar o Hyprland de $cur_ver para $new_ver mesmo assim?" || { restore; applied=1; exit 0; }

  sed -i "s|\(nixpkgs-hyprland.url = \"github:NixOS/nixpkgs/\)$current\"|\1$latest\"|" flake.nix
  nix flake update nixpkgs-hyprland
else
  bold "Atualizando inputs: ${inputs[*]}"
  nix flake update "${inputs[@]}"
fi

lock_changed=1
cmp -s flake.lock "$backup/flake.lock" && lock_changed=0

# ── 2. Build + diff + confirmação ───────────────────────────────────────────
if [[ "$lock_changed" -eq 1 ]]; then
  bold "Construindo o sistema novo (ainda sem aplicar)"
  ( cd "$WORK" && nixos-rebuild build --flake "$FLAKE#$HOST" )

  bold "O que muda em relação ao sistema atual"
  nix store diff-closures /run/current-system "$WORK/result" || true

  echo
  if ask "Aplicar estas mudanças agora (sudo nixos-rebuild switch)?"; then
    sudo nixos-rebuild switch --flake "$FLAKE#$HOST"
    applied=1
    bold "Aplicado."
    echo "flake.lock mudou e ainda NÃO foi commitado. Quando quiser:"
    echo "  cd $FLAKE && git add flake.lock flake.nix && git commit -m 'chore: update $group'"
    [[ "$group" == hyprland ]] && warn "Lembre de atualizar wiki/source locais, CLAUDE.md e a regra do Hyprland."
    [[ "$group" == sistema ]] && echo "Kernel/drivers novos só entram em uso depois de reiniciar."
  else
    restore
    applied=1 # já restaurado; não restaurar de novo no trap
  fi
else
  echo "Os inputs de '$group' já estavam na versão mais recente."
fi

# ── 3. Flatpaks (só no grupo Programas; independem do Nix) ──────────────────
if [[ "$group" == programas ]] && command -v flatpak >/dev/null; then
  bold "Flatpaks (usuário)"
  flatpak update --user -y --noninteractive || warn "flatpak update falhou (seguindo)."
fi
