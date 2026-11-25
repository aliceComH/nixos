<!--
Template para novos knowledge docs. Copie este arquivo para
.agents/knowledge/<nome-do-subsistema>.md e preencha as seções.
Não delete este comentário nos docs gerados a partir daqui.
-->

# Repos (Mapa de Pastas)

## O que é

GUI GTK3 que lista as pastas em que a Alice e o Claude trabalham e mostra, para
cada uma, se é repositório git, remote (origin), branch, mudanças não
commitadas, ahead/behind do upstream e o último commit.

## Por que existe

As pastas de trabalho estão espalhadas (`/etc/nixos`, `~/vault`, `~/.claude`,
`~/Documentos/...`) e nem todas são git; o mapa responde "o que é isto, está
versionado, está sincronizado?" sem abrir terminal. Segue o padrão da Central de
Updates: script Python solto no repo, rodado pelo `python` do sistema (que já
traz o PyGObject), sem pacote Nix próprio e sem daemon.

## Arquivos envolvidos

- `tools/repos/pastas.toml` — a lista de pastas (nome, caminho, descrição, cor). Único lugar para adicionar/remover pastas.
- `tools/repos/repos.py` — GUI e coleta. `--print` / `--json` imprimem o mapa sem abrir janela; `--fetch` roda `git fetch` antes.
- `config/hypr/hyprland/windowrules/floating.lua` — regra `repos.py` (float, 1100x900, centro). Só aplica depois de rebuild (`~/.config/hypr` vem do store via Home Manager).
- `modules/nixos/packages-system.nix` — `python3-with-gi` (o `python` com `gi`) usado pelo script.

## Depende de / Relacionado a

- **Fraco:** [updates](updates.md) — mesma família de GUI (estilo, empacotamento, forma de abrir); nenhuma dependência de código.

## Pontos de atenção

- Leitura é 100% local: ahead/behind compara com as refs remotas em cache. Só o botão "Atualizar remoto" (ou `--fetch`) vai à rede, com `GIT_TERMINAL_PROMPT=0` e timeout de 60 s por repo.
- Uma pasta só conta como repo se for a raiz (`rev-parse --show-toplevel` igual ao caminho); subpasta de outro repo aparece como "não é repositório git (fica dentro do repo X)".
- Arquivos não rastreados contam em "Mudanças" (uma pasta nova não rastreada conta como 1, como no `git status`).
- `~/.claude` É repositório git (origin `alice-ai`), ao contrário do que se supunha.
- O portfólio em Go é o `~/Projetos/combobreaker` (cartão em `pastas.toml`).
- Keybind **ALT+8** em `config/hypr/hyprland/keybinds.lua`: no nível principal e nos submaps auxiliar, whatsapp e media (ao lado do ALT+9). Fica fora dos submaps gaming e osu.
