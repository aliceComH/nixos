#!/usr/bin/env bash
# Atualiza UM grupo do sistema. Chamado pela Central de Updates (updates.py),
# mas funciona sozinho: update-group.sh <hyprland|osu|sistema|programas>
#
# Fluxo: atualiza os inputs do grupo -> build -> mostra o diff de versões ->
# pergunta -> só então aplica (nixos-rebuild switch). Se você recusar ou algo
# falhar, flake.nix e flake.lock voltam ao estado anterior.
#
# Hyprland é diferente: o botão só instala a versão que a skill /update-hyprland
# preparou (wiki + código-fonte baixados, sistema adequado e validado). Sem a
# fase "pronto" em hyprland-update.json ele não faz nada.
# Ver .agents/knowledge/hyprland-update.md.
#
# FONTE DA VERDADE do mapeamento grupo -> inputs. Se mudar aqui, mude também
# GROUPS em updates.py e o comentário no topo de flake.nix.
set -euo pipefail

FLAKE="${FLAKE:-/etc/nixos}"   # sobreponha só para ensaiar numa cópia do repo
HOST=alice-nixos
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/central-updates"
# Estado e patch gravados pela skill /update-hyprland (tools/updates/hyprland-update.sh).
HYPR_STATE="$FLAKE/tools/updates/hyprland-update.json"
HYPR_PATCH="$FLAKE/tools/updates/hyprland-adequacao.patch"

group="${1:-}"
case "$group" in
  hyprland)  inputs=(nixpkgs-hyprland nixpkgs-mesa) ;;
  osu)       inputs=(nixpkgs-osu) ;;
  sistema)   inputs=(nixpkgs home-manager) ;;
  programas) inputs=(nixpkgs-apps claude-desktop bedrock-on-linux) ;;
  *) echo "uso: $0 <hyprland|osu|sistema|programas>" >&2; exit 2 ;;
esac

bold() { printf '\n\033[1;35m== %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m%s\033[0m\n' "$*"; }
ask()  { local a; read -r -p "$1 [s/N] " a; [[ "$a" =~ ^[sS]$ ]]; }

mkdir -p "$WORK"
backup="$(mktemp -d)"
cp "$FLAKE/flake.lock" "$FLAKE/flake.nix" "$backup/"
applied=0

hypr_undo=0   # 1 depois que o fluxo do Hyprland mexeu no working tree
restore() {
  if [[ "$applied" -eq 0 ]]; then
    if [[ "$hypr_undo" -eq 1 ]]; then
      # A árvore estava limpa antes (pré-condição), então dá para desfazer pelo git.
      [[ -s "$HYPR_PATCH" ]] && git -C "$FLAKE" apply -R "$HYPR_PATCH" 2>/dev/null || true
      git -C "$FLAKE" checkout -- CLAUDE.md .agents/rules/hyprland-guidelines.md
      hyprctl eval 'hl.config({ misc = { disable_autoreload = false } })' >/dev/null 2>&1 || true
      hyprctl reload >/dev/null 2>&1 || true
    fi
    cp "$backup/flake.lock" "$backup/flake.nix" "$FLAKE/"
    warn "Arquivos restaurados — nada mudou no sistema."
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

  # O botão NÃO decide a versão nem baixa nada: só instala o que a skill
  # /update-hyprland preparou e validou. Sem isso, não faz nada.
  blocked() {
    echo
    warn "O botão não fez nada: $1"
    echo "Abra o Claude Code em $FLAKE e rode:  /update-hyprland"
    exit 0
  }
  st() { jq -r --arg k "$1" '.[$k] // empty' "$HYPR_STATE"; }

  bold "Checando a preparação do update (skill /update-hyprland)"
  [[ -f "$HYPR_STATE" ]] || blocked "nenhum update do Hyprland foi preparado."
  fase="$(st fase)"; new_ver="$(st versao_alvo)"; latest="$(st nixpkgs_rev)"
  cur_ver="$(nix eval --raw "github:NixOS/nixpkgs/$current#hyprland.version")"
  echo "Travado hoje: $cur_ver  (nixpkgs ${current:0:8})"
  echo "Preparado:    $new_ver  (nixpkgs ${latest:0:8}, fase: $fase)"

  case "$fase" in
    pronto) ;;
    baixado)   blocked "wiki e código-fonte da $new_ver foram baixados, mas a análise/adequação não terminou." ;;
    recusado)  blocked "você decidiu não adequar o sistema para a $new_ver." ;;
    instalado) blocked "a $new_ver já foi instalada; falta só a finalização pela skill." ;;
    *)         blocked "estado desconhecido ('$fase')." ;;
  esac
  [[ "$cur_ver" != "$new_ver" ]] || blocked "o Hyprland já está na $new_ver."
  [[ -d "source-code-hyprland-$new_ver" ]] || blocked "falta a pasta source-code-hyprland-$new_ver."
  [[ -d "wiki-hyprland-$new_ver" ]] || blocked "falta a pasta wiki-hyprland-$new_ver."
  [[ "$(nix eval --raw "github:NixOS/nixpkgs/$latest#hyprland.version")" == "$new_ver" ]] \
    || blocked "a rev preparada não entrega o Hyprland $new_ver."
  want_sum="$(st patch_sha256)"
  if [[ -n "$want_sum" ]]; then
    [[ -f "$HYPR_PATCH" && "$(sha256sum "$HYPR_PATCH" | cut -d' ' -f1)" == "$want_sum" ]] \
      || blocked "o patch de adequação sumiu ou mudou depois de validado."
  fi
  git diff --quiet && git diff --cached --quiet \
    || blocked "há mudanças não commitadas em $FLAKE. Faça commit (ou descarte) antes, para o update poder ser desfeito com segurança."
  [[ -z "$want_sum" ]] || git apply --check "$HYPR_PATCH" \
    || blocked "o patch de adequação não aplica mais no repo. Rode a skill de novo."

  echo
  if [[ -n "$want_sum" ]]; then
    echo "Adequação validada que será aplicada junto:"
    git apply --stat "$HYPR_PATCH" | sed 's/^/  /'
  else
    echo "Adequação: nenhuma mudança necessária na config."
  fi
  ask "Trocar o Hyprland de $cur_ver para $new_ver?" || { applied=1; exit 0; }

  hypr_undo=1
  # A config em config/hypr é link vivo: sem isto o Hyprland ANTIGO recarregaria
  # a config já adequada para a versão nova no meio do build.
  hyprctl eval 'hl.config({ misc = { disable_autoreload = true } })' >/dev/null 2>&1 || true
  [[ -z "$want_sum" ]] || git apply "$HYPR_PATCH"
  # Regras e wiki/código de referência passam a ser os da versão nova.
  sed -i "s/${cur_ver//./\\.}/$new_ver/g" CLAUDE.md .agents/rules/hyprland-guidelines.md
  # A Mesa acompanha o Hyprland (mesma rev = mesma glibc; ver amd-gpu.nix).
  sed -i "s|\(nixpkgs-hyprland.url = \"github:NixOS/nixpkgs/\)$current\"|\1$latest\"|" flake.nix
  sed -i "s|\(nixpkgs-mesa.url = \"github:NixOS/nixpkgs/\)[0-9a-f]\{40\}\"|\1$latest\"|" flake.nix
  nix flake update nixpkgs-hyprland nixpkgs-mesa
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
    echo "flake.lock mudou e ainda NÃO foi commitado."
    [[ "$group" == hyprland ]] || echo "Quando quiser:  cd $FLAKE && git add flake.lock flake.nix && git commit -m 'chore: update $group'"
    if [[ "$group" == hyprland ]]; then
      tmp="$(mktemp)"; jq --arg d "$(date +%F)" '.fase = "instalado" | .atualizado_em = $d' "$HYPR_STATE" > "$tmp" && mv "$tmp" "$HYPR_STATE"
      warn "O Hyprland em execução ainda é o $cur_ver, com a config antiga em memória."
      warn "Reinicie a sessão (ou a máquina) e depois rode /update-hyprland para finalizar"
      warn "(conferir a versão, remover wiki/código antigos e commitar)."
      ask "Reiniciar a máquina agora?" && systemctl reboot
    fi
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
