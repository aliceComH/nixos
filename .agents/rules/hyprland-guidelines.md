---
trigger: always_on
---

# Regras de Workspace: Configuração do Hyprland

## Contexto do Sistema
- **Alvo:** Hyprland
- **Versão Estrita:** 0.55.4
- **Ambiente:** NixOS (Em transição de Dotfiles puros para Home Manager)
- **Diretório Raiz:** `/etc/nixos`

## Diretrizes de Resolução (Lookup Order)
Para qualquer dúvida de sintaxe, funcionalidade, variáveis ou comportamento do Hyprland, você **DEVE** seguir estritamente a ordem de consulta abaixo. Pare a busca na primeira etapa que fornecer a informação necessária para a resolução do problema:

### 1. Wiki Local (Prioridade Máxima)
- **Diretório:** `/etc/nixos/wiki-hyprland-0.55.4`
- **Ação:** Consulte os arquivos Markdown desta pasta primeiro. Esta é a fonte absoluta da verdade para a sintaxe suportada pela configuração atual.

### 2. Código-Fonte Local (Prioridade Secundária)
- **Diretório:** `/etc/nixos/source-code-hyprland-0.55.4`
- **Ação:** Se a Wiki local não contiver a resposta ou a documentação for ambígua, consulte o código-fonte (especialmente os arquivos de header `.hpp` para definições de variáveis e dispatchers).
- **Objetivo:** Verificar a implementação real da versão 0.55.4.

### 3. Busca na Internet (Último Recurso)
- **Ação:** Utilize a internet apenas se as duas fontes locais falharem completamente.
- **Restrição Crítica:** Qualquer busca na web deve explicitamente procurar por referências à versão **0.55.4**. Rejeite ativamente fóruns, tutoriais ou documentações que utilizem propriedades ou funcionalidades introduzidas em versões `> 0.55.4`.

## Restrições Comportamentais do Agente
- **Zero Alucinações de Versão:** Nunca presuma que a sintaxe "latest" (mais recente) é aplicável.
- **Resolução de Conflitos:** Se houver divergência técnica entre informações encontradas na internet e os arquivos locais, a Wiki/Código locais **sempre** têm precedência.
- **Geração de Código Dinâmica:** 
  - Se estiver editando ou criando arquivos `.conf`: Use a sintaxe nativa pura do Hyprland.
  - Se estiver editando ou criando arquivos `.nix` (Home Manager): Traduza a configuração nativa para o formato declarativo Nix, utilizando a estrutura `wayland.windowManager.hyprland.settings`.