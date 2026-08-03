---
trigger: always_on
---

# Regra: Knowledge Docs (`.agents/knowledge/`)

## Propósito

`.agents/knowledge/` é um grafo de conhecimento **para você (IA)**, não para o
usuário — inspirado no Graphify. Cada doc mapeia um subsistema que atravessa
múltiplos arquivos (instalação, config, scripts, integrações), incluindo
ligações não-óbvias que um grep simples não revela.

Isto existe porque decisões de design tomadas numa sessão se perdem na
próxima. Os docs preservam o "porquê", não só o "o quê".

## Quando consultar

Antes de mexer em qualquer subsistema (ex.: mpv, voice-normalizer, LLM, DNS),
verifique `.agents/knowledge/_index.md`. Se existir um doc relacionado, leia-o
antes de editar — ele pode revelar dependências em arquivos que você não
tocaria por conta própria.

## Quando criar/atualizar um doc

Depois de uma mudança que atravessa **múltiplos arquivos** de um mesmo
subsistema (ex.: pacote + config + script + regra do Hyprland):

1. Copie `.agents/knowledge/_template.md` para `.agents/knowledge/<nome>.md`
   (ou edite o doc já existente do subsistema).
2. Preencha as seções do template. Seja objetivo — o público é você mesmo em
   uma sessão futura, não precisa de prosa.
3. Marque links para outros docs como **Forte** (dependência real, quebra se
   o outro lado sumir) ou **Fraco** (relação incidental/cosmética).
4. Adicione o doc à tabela e ao grafo mermaid em `_index.md`.

## Regras de conteúdo

- Um doc por subsistema, nomeado pelo subsistema (`mpv.md`, não
  `media-player.md`).
- Mantenha pequeno — se o doc passar de ~150 linhas, provavelmente cobre mais
  de um subsistema e deveria ser dividido.
- Cite caminhos de arquivo reais e o papel de cada um, não resumos vagos.
- Se encontrar algo quebrado/pendente (referência a comando que não existe,
  comentário desatualizado, etc.) durante o mapeamento, registre em "Pontos
  de atenção" em vez de silenciosamente ignorar ou corrigir sem avisar.
- Não duplique o que já está no `README.md` (instruções de uso para humanos)
  — foque em dependências e decisões, não em "como usar".
