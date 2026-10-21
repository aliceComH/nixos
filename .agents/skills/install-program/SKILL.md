---
name: install-program
description: >-
  Use SEMPRE que Alice pedir para instalar, adicionar ou configurar um programa/pacote
  no sistema NixOS (ex.: "instala o X", "bota o X no meu sistema"). Pergunta via ask_question
  se quer módulo separado, depois qual keybind do Hyprland, de forma idempotente,
  sempre excluindo os submaps "gaming" e "osu".
---

# Instalação de programas (NixOS + Hyprland Lua)

Siga os passos NA ORDEM. Use SEMPRE a ferramenta `ask_question` para as perguntas
(nunca pergunte em texto corrido). Antes de começar, consulte
`.agents/knowledge/_index.md` caso o programa pertença a um subsistema existente.

## 1. Pergunta: módulo separado?

`ask_question` com opções:
- "(Recomendado, se o programa tiver config própria) Módulo separado"
- "Apenas adicionar em packages-system.nix"
- "Apenas adicionar em packages-home.nix (Home Manager)"

Se Alice não souber, recomende módulo separado quando houver serviço, opções
`programs.<x>`, udev, config files ou env vars; caso contrário, lista de pacotes.

### Se módulo separado
- Criar `modules/nixos/<programa>.nix` (ou `modules/home/` se for Home Manager).
- Registrar em `imports` de `hosts/alice-nixos/configuration.nix` (ou no equivalente home).
- Preferir `programs.<x>.enable = true` quando existir; senão `environment.systemPackages`.
- Idempotência: se o módulo/import/pacote já existir, NÃO duplicar; avise e siga.

### Se lista de pacotes
- Adicionar em `modules/nixos/packages-system.nix` (ou `modules/home/packages-home.nix`),
  em ordem coerente com os vizinhos; não duplicar se já presente.

## 2. Pergunta: keybind

`ask_question`: "Quer keybind para o programa?" (Sim / Não). Se sim, perguntar qual
(opções sugeridas livres + write-in), no formato Hyprland Lua, ex.: `ALT + T`.

### Checagem de conflito (idempotência, obrigatória ANTES de escrever)
1. Normalizar a combinação (case-insensitive, ordem dos modificadores irrelevante).
2. `grep -n -i` no arquivo `config/hypr/hyprland/keybinds.lua` (e demais `*.lua` em
   `config/hypr/`) procurando `hl.bind("<combo>"`, em escopo global E em todos os
   `hl.define_submap`.
3. Se a combinação já existir em QUALQUER lugar relevante (global ou submap alvo):
   **BLOQUEIE** — não sobrescreva — e use `ask_question` mostrando onde conflita
   (linha e comando) pedindo outra keybind. Repita até obter uma livre.
4. Se o mesmo comando exato já estiver ligado à keybind escolhida, não duplicar.

### Onde inserir
- Escopo global (fora de submap) + TODOS os submaps definidos em `keybinds.lua`,
  **EXCETO `gaming` e `osu`** (nunca adicionar nesses dois, sem exceção).
- Descobrir os submaps dinamicamente: `grep -n 'hl.define_submap' keybinds.lua`
  (não assumir a lista; novos submaps devem ser incluídos automaticamente).
- Inserir junto das demais binds de programas (ex.: após `ALT + C` / `antigravity-ide`),
  respeitando indentação (4 espaços dentro de submap).
- Formato: `hl.bind("ALT + T", hl.dsp.exec_cmd("<binário>"))`.
- Atenção: o arquivo usa finais de linha CRLF; `replace_file_content` pode falhar
  no match — nesse caso use `sed -i` ancorado em linha existente.
- Verificar o nome real do binário (`meta.mainProgram`/`nix eval`), não presumir.

## 3. Finalização

- Validar com `grep -c` que a bind apareceu em N = (submaps − 2) + 1 lugares.
- Não rodar `nixos-rebuild` sem pedir; informar o comando:
  `sudo nixos-rebuild switch --flake /etc/nixos#alice-nixos` e `hyprctl reload`.
- Se a mudança atravessou vários arquivos de um subsistema, seguir
  `.agents/rules/knowledge-docs.md` (criar/atualizar doc em `.agents/knowledge/`).
- Respeitar `.agents/rules/pipewire-quantum.md` se o programa mexer em áudio.
