#!/usr/bin/env bash
# Preparação do update do Hyprland. É a parte determinística da skill
# /update-hyprland (.claude/skills/update-hyprland/SKILL.md); o botão "Atualizar
# Hyprland" da Central (update-group.sh) só lê o estado que este script grava.
#
# Estado: tools/updates/hyprland-update.json (versionado). Fases:
#   baixado   -> wiki e código-fonte da versão alvo já estão no repo
#   pronto    -> adequação feita e validada; o botão está liberado
#   recusado  -> a Alice decidiu não adequar; o botão segue travado
#   instalado -> o botão aplicou o update; falta a finalização pela skill
#
# Uso: hyprland-update.sh <descobrir|baixar|worktree|verificar|selar|recusar|finalizar|estado>
# Ver .agents/knowledge/hyprland-update.md.
set -euo pipefail

FLAKE="${FLAKE:-/etc/nixos}"   # sobreponha só para ensaiar numa cópia do repo
STATE="$FLAKE/tools/updates/hyprland-update.json"
PATCH="$FLAKE/tools/updates/hyprland-adequacao.patch"
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/central-updates"
WT="$WORK/hyprland-adequacao"

die()  { printf 'erro: %s\n' "$*" >&2; exit 1; }
info() { printf '%s\n' "$*" >&2; }

pinned_rev() {
  sed -n 's|.*nixpkgs-hyprland.url = "github:NixOS/nixpkgs/\([0-9a-f]\{40\}\)".*|\1|p' "$FLAKE/flake.nix"
}
hypr_version_at() { nix eval --raw "github:NixOS/nixpkgs/$1#hyprland.version"; }
state_get() { [[ -f "$STATE" ]] && jq -r --arg k "$1" '.[$k] // empty' "$STATE" || true; }
state_set() { # pares chave valor (strings)
  local tmp; tmp="$(mktemp)"
  [[ -f "$STATE" ]] || echo '{}' > "$STATE"
  local args=() filter='.'
  while [[ $# -gt 0 ]]; do
    args+=(--arg "k$#" "$1" --arg "v$#" "$2"); filter+=" | .[\$k$#] = \$v$#"; shift 2
  done
  jq "${args[@]}" "$filter" "$STATE" > "$tmp" && mv "$tmp" "$STATE"
}
need_state() { [[ -f "$STATE" ]] || die "sem estado ($STATE). Comece por 'baixar'."; }

cmd="${1:-estado}"; shift || true
mkdir -p "$WORK"
cd "$FLAKE"

case "$cmd" in
  # ── Versões: travada, upstream e a que o nixos-unstable entrega ────────────
  descobrir)
    cur_rev="$(pinned_rev)"; [[ -n "$cur_rev" ]] || die "não achei a rev do nixpkgs-hyprland em flake.nix"
    new_rev="$(nix flake metadata github:NixOS/nixpkgs/nixos-unstable --json | jq -r .locked.rev)"
    upstream="$(git ls-remote --tags --refs https://github.com/hyprwm/Hyprland \
      | sed -n 's|.*refs/tags/v\([0-9][0-9.]*\)$|\1|p' | sort -V | tail -1)"
    jq -n --arg cr "$cur_rev" --arg cv "$(hypr_version_at "$cur_rev")" \
          --arg nr "$new_rev" --arg nv "$(hypr_version_at "$new_rev")" --arg up "$upstream" \
      '{travado: {versao: $cv, rev: $cr}, nixos_unstable: {versao: $nv, rev: $nr}, upstream: $up}'
    ;;

  # ── Baixa código-fonte e wiki da versão alvo para a raiz do repo ───────────
  baixar)
    ver="${1:-}"; rev="${2:-}"
    [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$rev" =~ ^[0-9a-f]{40}$ ]] || die "uso: baixar <versão> <rev do nixpkgs>"
    got="$(hypr_version_at "$rev")"
    [[ "$got" == "$ver" ]] || die "o nixpkgs $rev entrega o Hyprland $got, não $ver"
    src="source-code-hyprland-$ver"; wiki="wiki-hyprland-$ver"
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

    if [[ -d "$src" ]]; then info "$src já existe, mantendo."; else
      info "Baixando o código-fonte v$ver..."
      curl -fsSL "https://github.com/hyprwm/Hyprland/archive/refs/tags/v$ver.tar.gz" -o "$tmp/src.tar.gz"
      mkdir "$tmp/src" && tar -xzf "$tmp/src.tar.gz" -C "$tmp/src" --strip-components=1
      [[ "$(tr -d '[:space:]' < "$tmp/src/VERSION")" == "$ver" ]] || die "o tarball não é da versão $ver"
      mv "$tmp/src" "$src"
    fi
    # O git archive grava em todo arquivo a data do commit da tag.
    tag_ts="$(stat -c %Y "$src/VERSION")"

    if [[ -d "$wiki" ]]; then
      info "$wiki já existe, mantendo."
      wiki_commit="$(state_get wiki_commit)"
    else
      # A wiki não tem tags: usa-se o último commit do main até a data da tag
      # (o que estava documentado quando a versão saiu). WIKI_REF sobrepõe.
      info "Baixando a wiki..."
      git clone -q --filter=blob:none https://github.com/hyprwm/hyprland-wiki "$tmp/wiki"
      wiki_commit="${WIKI_REF:-$(git -C "$tmp/wiki" rev-list -1 --before="@$tag_ts" origin/main)}"
      [[ -n "$wiki_commit" ]] || die "não achei commit da wiki anterior à tag v$ver"
      git -C "$tmp/wiki" checkout -q "$wiki_commit"
      [[ -d "$tmp/wiki/content" ]] || die "a wiki mudou de estrutura (sem content/)"
      cp -r "$tmp/wiki/content" "$wiki"
    fi

    cur_rev="$(pinned_rev)"
    rm -f "$PATCH"; echo '{}' > "$STATE"
    state_set fase baixado versao_alvo "$ver" nixpkgs_rev "$rev" \
      versao_atual "$(hypr_version_at "$cur_rev")" rev_atual "$cur_rev" \
      wiki_commit "$wiki_commit" tag_data "$(date -d "@$tag_ts" +%F)" atualizado_em "$(date +%F)"
    cat "$STATE"
    ;;

  # ── Cópia isolada do repo para fazer a adequação sem tocar na config viva ──
  worktree)
    need_state
    git worktree remove --force "$WT" 2>/dev/null || rm -rf "$WT"
    git worktree prune
    git worktree add -q --detach "$WT" HEAD
    echo "$WT"
    ;;

  # ── Valida a config Lua com o binário da versão ALVO (não inicia sessão) ───
  verificar)
    need_state
    dir="${1:-$WT}"; [[ -f "$dir/config/hypr/hyprland.lua" ]] || die "sem config em $dir"
    rev="$(state_get nixpkgs_rev)"
    hypr="$(nix build --no-link --print-out-paths "github:NixOS/nixpkgs/$rev#hyprland^out" | head -1)"
    info "Verificando $dir/config/hypr com $("$hypr/bin/Hyprland" --version | head -1 | cut -d' ' -f1-2)"
    # O --verify-config executa os hl.exec_cmd do topo da config. Sem a assinatura
    # da instância, um `hyprctl` chamado dali não alcança a sessão em uso.
    out="$(env -u HYPRLAND_INSTANCE_SIGNATURE timeout 60 "$hypr/bin/Hyprland" --verify-config \
      --config "$dir/config/hypr/hyprland.lua" 2>&1 || true)"
    printf '%s\n' "$out" | sed -n '/Config parsing result/,$p'
    printf '%s\n' "$out" | grep -qx 'config ok' || die "a config tem erros na versão alvo (acima)"
    ;;

  # ── Fecha a adequação: gera o patch, valida e libera o botão ───────────────
  selar)
    need_state
    [[ -d "$WT" ]] || die "sem worktree de adequação. Rode 'worktree' e faça as mudanças lá."
    "$0" verificar "$WT" >&2 || die "a config adequada não passou no --verify-config da versão alvo"
    git -C "$WT" add -A
    git -C "$WT" diff --cached --binary HEAD > "$PATCH"
    if [[ -s "$PATCH" ]]; then
      git apply --check "$PATCH" || die "o patch não aplica no /etc/nixos atual (o repo mudou depois do worktree?)"
      sum="$(sha256sum "$PATCH" | cut -d' ' -f1)"
    else
      rm -f "$PATCH"; sum=""   # nada a adequar: a config atual já serve
    fi
    git worktree remove --force "$WT"
    state_set fase pronto patch_sha256 "$sum" atualizado_em "$(date +%F)"
    cat "$STATE"
    ;;

  recusar)
    need_state
    git worktree remove --force "$WT" 2>/dev/null || true
    rm -f "$PATCH"
    state_set fase recusado patch_sha256 "" atualizado_em "$(date +%F)"
    cat "$STATE"
    ;;

  # ── Depois do botão + reinício da sessão: confere e limpa o estado ─────────
  finalizar)
    need_state
    [[ "$(state_get fase)" == instalado ]] || die "fase atual é '$(state_get fase)', não 'instalado'"
    alvo="$(state_get versao_alvo)"
    rodando="$(hyprctl version -j | jq -r .version)"
    [[ "$rodando" == "$alvo" ]] || die "o Hyprland em execução é $rodando, não $alvo. Reinicie a sessão antes."
    rm -f "$STATE" "$PATCH"
    echo "Hyprland $alvo em execução. Estado limpo."
    ;;

  estado)
    if [[ -f "$STATE" ]]; then cat "$STATE"; else echo '{"fase": "nenhum"}'; fi
    ;;

  *) die "comando desconhecido: $cmd" ;;
esac
