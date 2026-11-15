<!--
Template para novos knowledge docs. Copie este arquivo para
.agents/knowledge/<nome-do-subsistema>.md e preencha as seções.
Não delete este comentário nos docs gerados a partir daqui.
-->

# hyprland-update (fluxo de atualização do Hyprland)

## O que é

O caminho único para trocar a versão do Hyprland: a skill `/update-hyprland` prepara
(baixa referência, analisa, adequa o sistema, valida) e o botão "Atualizar Hyprland" da
Central de Updates só instala o que ela liberou.

## Por que existe

O Hyprland é travado por rev e a config é Lua escrita contra uma versão exata; a wiki e o
código-fonte dessa versão ficam no repo e são a fonte da verdade
(`.agents/rules/hyprland-guidelines.md`). Antes, o botão trocava a rev direto e só avisava
que a config "podia quebrar". Agora nada é instalado sem: referência da versão nova no repo,
análise de impacto no nosso sistema, aprovação da Alice e config validada pelo binário novo.

## Fases (`tools/updates/hyprland-update.json`)

| Fase | Quem grava | Significa | Botão |
|---|---|---|---|
| (sem arquivo) | — | nada preparado | não faz nada |
| `baixado` | `hyprland-update.sh baixar` | wiki + código da versão alvo no repo | não faz nada |
| `recusado` | `... recusar` | Alice não quis adequar | não faz nada |
| `pronto` | `... selar` | adequação feita, validada, patch com hash | **liberado** |
| `instalado` | `update-group.sh` | switch feito; falta reiniciar e finalizar | não faz nada |
| (arquivo removido) | `... finalizar` | versão nova conferida em execução | — |

## Arquivos envolvidos

- `.claude/skills/update-hyprland/SKILL.md` — o roteiro (descobrir, baixar, analisar, plano, pergunta, adequar, liberar, finalizar).
- `tools/updates/hyprland-update.sh` — parte mecânica: `descobrir`, `baixar`, `worktree`, `verificar`, `selar`, `recusar`, `finalizar`, `estado`.
- `tools/updates/update-group.sh` (ramo `hyprland`) — checa o estado, aplica o patch, troca as revs, build, diff, confirmação, switch; desfaz tudo se falhar ou for recusado.
- `tools/updates/hyprland-update.json` — estado (versão alvo, rev do nixpkgs validada, commit da wiki, hash do patch). Versionado.
- `tools/updates/hyprland-adequacao.patch` — mudanças no sistema para a versão nova. Só existe entre `selar` e `finalizar`.
- `tools/updates/hyprland-plano-<versão>.md` — plano apresentado à Alice. Fica como registro.
- `source-code-hyprland-<versão>/`, `wiki-hyprland-<versão>/` — referência; a antiga só sai na finalização.
- `flake.nix` — `nixpkgs-hyprland` e `nixpkgs-mesa`, as duas revs que o botão troca.
- `CLAUDE.md`, `.agents/rules/hyprland-guidelines.md` — o botão troca a versão citada (sed) no momento da instalação.

## Depende de / Relacionado a

- **Forte:** [updates](updates.md) — o botão e o mapeamento de grupos vivem lá; a Mesa (`nixpkgs-mesa`) sobe junto com o Hyprland.
- **Fraco:** [gtk-theme](gtk-theme.md) — windowrules do Thunar são conferidas na finalização.

## Decisões de design

- **Alvo = versão do `nixos-unstable`**, não a última tag upstream: é o que o Nix consegue instalar. A rev validada fica no estado e é exatamente ela que o botão usa (não "a mais nova na hora do clique").
- **Adequação vira patch, não edição direta.** `~/.config/hypr` é link vivo para `config/hypr`: editar ali quebraria a sessão que ainda roda a versão antiga. A skill edita num git worktree (`~/.cache/central-updates/hyprland-adequacao`), valida e gera o patch; o botão aplica junto com a troca de rev.
- **Autoreload desligado durante o botão** (`misc.disable_autoreload` via `hyprctl eval`), pelo mesmo motivo. A sessão antiga segue com a config antiga em memória até reiniciar.
- **Árvore git limpa é pré-condição do botão**: é o que permite desfazer com `git apply -R` + `git checkout`.
- **Validação = `Hyprland --verify-config` do binário alvo** (`nix build nixpkgs/<rev>#hyprland^out`). Pega erro de sintaxe/API Lua; não pega mudança de comportamento, por isso a análise de changelog/diff continua obrigatória.
- **Wiki sem tags upstream:** snapshot = último commit do `main` de `hyprwm/hyprland-wiki` até a data da tag (`WIKI_REF=<commit>` sobrepõe). O commit usado fica no estado.

## Pontos de atenção

- O `--verify-config` EXECUTA os `hl.exec_cmd` do topo da config (hoje: `hyprctl dispatch submap global`). O script roda sem `HYPRLAND_INSTANCE_SIGNATURE` para isso não atingir a sessão em uso; não adicione `exec_cmd` com efeito colateral no topo de `hyprland.lua`.
- Mudanças em `.nix` dentro do patch só são validadas de verdade pelo build do botão (o worktree não tem a rev nova).
- O sed do botão troca TODA ocorrência da versão antiga em `CLAUDE.md` e na regra do Hyprland; não cite ali versões que não devam mudar.
- Se o `nixos-unstable` avançar depois do `selar`, o botão ainda instala a versão validada. Para pegar a mais nova, rode a skill de novo.
- O código-fonte baixado é o tarball da tag (sem submódulos, como a pasta atual).
- Em 0.55.4 → 0.57.2 a wiki upstream mudou o nome das pastas para minúsculas (`configuring/` em vez de `Configuring/`); caminhos citados em docs podem mudar.

## Histórico

- 2026-11-15: fluxo criado. Ensaio do `--verify-config` do 0.57.2 sobre a config da 0.55.4: "config ok" (só sintaxe; análise completa ainda não feita).
