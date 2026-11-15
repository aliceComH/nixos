---
name: update-hyprland
description: >-
  Use quando a Alice chamar /update-hyprland ou pedir para atualizar o Hyprland ("atualiza o
  hyprland", "tem versão nova do hyprland?", "prepara o update do hyprland"). Baixa a wiki e o
  código-fonte da versão nova para o repo, analisa o que quebra no sistema, propõe um plano de
  adequação, implementa se ela aprovar e só então libera o botão da Central de Updates.
---

# Update do Hyprland

Quem instala é o botão "Atualizar Hyprland" da Central (`tools/updates/update-group.sh`).
Esta skill só **prepara e libera**: o botão recusa tudo que não estiver na fase `pronto` em
`tools/updates/hyprland-update.json`. Nunca troque a rev do `nixpkgs-hyprland` à mão e nunca
rode `nix flake update nixpkgs-hyprland` por fora deste fluxo.

Toda a parte mecânica está em `tools/updates/hyprland-update.sh` (chame-o de `H` abaixo).
Antes de começar, leia `.agents/knowledge/hyprland-update.md`.

## 0. Onde estamos

Rode `H estado` e retome pela fase:

| Fase | Ir para |
|---|---|
| `nenhum` | passo 1 |
| `baixado` | passo 3 (análise) |
| `recusado` | pergunte se ela quer reavaliar; se sim, passo 3 |
| `pronto` | avise que o botão já está liberado; nada a fazer |
| `instalado` | passo 7 (finalização) |

## 1. Descobrir a versão

`H descobrir` devolve a versão travada, a do `nixos-unstable` (com a rev) e a última tag upstream.

- **O alvo é sempre a versão do `nixos-unstable`**: é a única que o botão consegue instalar.
- Se o upstream estiver à frente do nixpkgs, avise e siga com a do nixpkgs.
- Se a travada já for a do nixpkgs, diga isso e pare.

## 2. Baixar wiki e código-fonte

`H baixar <versão> <rev>` cria `source-code-hyprland-<versão>/` e `wiki-hyprland-<versão>/` na
raiz do repo (mesmo formato das pastas da versão atual) e grava a fase `baixado`.

- A wiki upstream não tem tags: o script pega o último commit do `main` até a data da tag.
  Por isso ela pode citar algo que só existe na versão seguinte. **Em dúvida, o código-fonte
  baixado manda.**
- As pastas da versão antiga ficam onde estão até a finalização: a regra
  `.agents/rules/hyprland-guidelines.md` continua valendo para a versão em execução.

## 3. Analisar o que quebra

Objetivo: lista fechada do que, **no nosso sistema**, muda de comportamento ou deixa de funcionar.
Não liste mudanças upstream que não nos tocam.

1. **Teste direto primeiro:** `H verificar /etc/nixos` roda o `--verify-config` do binário novo
   sobre a config atual. Cada erro é um item do plano. Passar limpo não prova que nada quebra
   (ele não pega mudança de comportamento, só de sintaxe/API).
2. **Changelog:** leia as notas de release de TODAS as versões entre a atual e a alvo
   (`https://github.com/hyprwm/Hyprland/releases/tag/v<x>`), com foco em "breaking changes".
3. **Diff de referência:** compare a pasta antiga com a nova onde a nossa config encosta:
   - API Lua e opções: `src/config/`, descrições de variáveis, dispatchers, `hyprctl`
     (`diff -ru source-code-hyprland-<antiga>/src/config source-code-hyprland-<nova>/src/config`).
   - Wiki: `Configuring/` (o nome das pastas pode ter mudado de caixa entre versões).
4. **Inventário do nosso uso** e cruzamento com 1 a 3:
   - `config/hypr/**` (Lua, `hyprpaper.conf`, shaders) e todos os scripts em
     `config/hypr/hyprland/scripts/` que chamam `hyprctl` (comandos, campos do JSON, dispatchers).
   - Nix: `modules/nixos/hyprland-system.nix`, `modules/home/hypr-user-services.nix`,
     `modules/home/zsh.nix` (`start-hyprland`), portais (`config/xdg-desktop-portal/`), e qualquer
     outro uso de `pkgs-hyprland` ou `hyprctl` (`grep -rn` fora das pastas de wiki/código).
   - Skills e docs que dependem de sintaxe: `.claude/skills/install-program/SKILL.md`,
     `.agents/knowledge/*.md`.
   - Dependências de build: o `nixpkgs-mesa` passa a usar a mesma rev do Hyprland (o botão troca
     as duas). Confira com `nix eval` que a glibc da rev nova é <= a do `nixpkgs` do sistema; se
     não for, o item "atualizar o grupo Sistema antes" entra no plano.

Para cada item ache a evidência (arquivo:linha nosso + trecho da wiki/código/changelog novo).
Sem evidência, não é item.

## 4. Plano e decisão da Alice

Salve o plano em `tools/updates/hyprland-plano-<versão>.md` e mostre um resumo no chat:

- o que quebra (item, onde, evidência) e o que muda de comportamento sem quebrar;
- para cada item, a mudança proposta para o sistema funcionar **igual a hoje**;
- o que não dá para manter igual, se houver, e a alternativa;
- o que fica de fora de propósito.

Depois pergunte com `AskUserQuestion` (uma pergunta, opções: adequar o sistema e liberar o
botão / não atualizar agora). **Não implemente nada antes da resposta.** Mesmo que a análise
não ache nada, mostre isso e pergunte.

Se ela recusar: `H recusar`, e pare. As pastas baixadas ficam (pergunte se quer removê-las).

## 5. Implementar a adequação (fora da config viva)

`~/.config/hypr` aponta para `/etc/nixos/config/hypr`: editar ali muda na hora a sessão que
ainda roda a versão ANTIGA. Por isso a adequação é feita numa cópia e vira um patch.

1. `H worktree` imprime o caminho de um git worktree do HEAD. **Edite só lá dentro.**
2. Aplique cada item do plano, seguindo a wiki/código da versão NOVA (para estes arquivos a
   regra de lookup aponta para as pastas novas).
3. `H verificar` (sem argumento = worktree) até passar limpo. Mudanças em `.nix` não dá para
   avaliar com a rev nova sem trocar o flake: cheque só a sintaxe (`nix-instantiate --parse`)
   e anote no plano o que apenas o build do botão vai validar.
4. Não altere no worktree: `flake.nix`, `flake.lock`, `CLAUDE.md`,
   `.agents/rules/hyprland-guidelines.md` nem as pastas de wiki/código. O botão cuida deles.
5. `H selar` gera `tools/updates/hyprland-adequacao.patch`, revalida, confere que o patch aplica
   no repo e grava a fase `pronto` com o hash do patch. Sem mudanças, sela sem patch.

## 6. Liberar o botão

O botão exige a árvore git limpa (para conseguir desfazer tudo se o build falhar). Então:

1. Peça **commit e push** (uma pergunta só) das pastas novas, do estado, do plano e do patch.
2. Diga para ela clicar em "Atualizar Hyprland" na Central e explique o que vai ver: checagem,
   resumo do patch, build, diff de versões, confirmação, e no fim a oferta de reiniciar.
3. Avise: depois do botão a sessão ainda roda a versão antiga até reiniciar, e ela deve chamar
   `/update-hyprland` de novo depois do reinício.

## 7. Finalização (fase `instalado`, depois do reinício)

1. `H finalizar` confere que o Hyprland em execução é o alvo e apaga estado e patch.
   `hyprctl configerrors` tem que vir vazio; se não vier, conserte antes de seguir.
2. Confira o que o plano listou como "muda de comportamento" e as regras do Thunar
   (as duas grafias da classe).
3. Pergunte se pode remover `source-code-hyprland-<antiga>/` e `wiki-hyprland-<antiga>/`
   (`git rm -r`). Só remova com o sim.
4. Atualize o que cita a versão: `CLAUDE.md` e a regra já foram trocados pelo botão; revise
   `.agents/knowledge/` e `install-program/SKILL.md` se a sintaxe mudou.
5. Acrescente uma linha datada em `.agents/knowledge/hyprland-update.md` (seção Histórico) com
   versão, o que precisou adequar e qualquer surpresa.
6. Peça commit e push.
