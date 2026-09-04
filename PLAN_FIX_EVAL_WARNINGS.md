# Plano: resolver os `evaluation warning` do `nixos-rebuild`

Contexto: depois de atualizar o input `nixpkgs` (2026-07-26 → 2026-08-23, para
pegar o zen 7.1.9 — ver `kernel-zen.nix`), o `nixos-rebuild switch` passou a
imprimir:

```
evaluation warning: stdenv.isLinux is deprecated, use stdenv.hostPlatform.isLinux instead
evaluation warning: stdenv.isDarwin is deprecated, use stdenv.hostPlatform.isDarwin instead
evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
```

Nenhum destes é um erro — o build/switch completa normalmente. São avisos de
depreciação de atributos "atalho" do `stdenv`/`pkgs`.

## Causa raiz

O branch `nixos-25.11` do nixpkgs acabou de ser criado (ago/2026) e, junto
com isso, os atributos "atalho" `stdenv.isLinux`, `stdenv.isDarwin` e
`pkgs.system` foram marcados como deprecated em favor de:

- `stdenv.hostPlatform.isLinux`
- `stdenv.hostPlatform.isDarwin`
- `pkgs.stdenv.hostPlatform.system` (ou `stdenv.hostPlatform.system` dentro
  de um pacote)

Fonte: [NixOS Discourse — how to fix the `system` warning](https://discourse.nixos.org/t/how-to-fix-evaluation-warning-system-has-been-renamed-to-replaced-by-stdenv-hostplatform-system/72120)
e [issue relacionada no nur do charmbracelet](https://github.com/charmbracelet/nur/issues/37)
(confirma que é uma migração em massa, ainda em andamento, ligada à
bifurcação do 25.11).

Isso significa que a **maioria** destes warnings vem de pacotes *dentro do
próprio nixpkgs* que ainda não foram migrados para a nova convenção — não é
algo que controlamos.

## O que é nosso vs. o que é do nixpkgs

- **`pkgs.system` — é nosso.** Aparece em
  [`modules/home/packages-home.nix`](modules/home/packages-home.nix) (linhas
  14-16), usado para indexar os pacotes do flake `antigravity-nix`:

  ```nix
  inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity
  ```

  Isso é seguro de corrigir agora.

- **`stdenv.isLinux` / `stdenv.isDarwin` — não é nosso.** Confirmei via
  `grep` no source do nixpkgs baixado (`pkgs/stdenv/generic/make-derivation.nix`
  e outros) que é código interno do próprio nixpkgs ainda usando o atributo
  antigo em pacotes que não migraram. Não há um único arquivo pra "corrigir"
  — é um esforço de migração em massa do upstream. Vai desaparecer
  naturalmente conforme o nixpkgs for atualizado (novos `nix flake update`).

## Passos

1. **Corrigir `pkgs.system` em `packages-home.nix`** (nosso código, ganho
   real):

   ```nix
   # antes
   inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity

   # depois
   inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity
   ```

   Aplicar nas 3 linhas (`google-antigravity`, `-ide`, `-cli`).

2. **Rebuildar e comparar a contagem de warnings antes/depois**, para
   confirmar quantos eram nossos vs. do upstream:

   ```bash
   sudo nixos-rebuild build --flake /etc/nixos#alice-nixos 2>&1 | grep -c "evaluation warning"
   ```

3. **Não perseguir os warnings de `isLinux`/`isDarwin`** — são do upstream.
   Opcionalmente, revisitar depois de um `nix flake update nixpkgs` futuro
   (podem já ter sido corrigidos lá).

4. Depois de aplicar o passo 1, rodar `sudo nixos-rebuild switch` de novo
   para ativar (não deve mudar nada em runtime, é só limpeza de warning).

## Retomando este plano

Depois do reboot, é só pedir para aplicar os passos 1-4 acima — nenhuma
outra investigação é necessária, já está tudo mapeado.
