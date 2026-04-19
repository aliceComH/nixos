# nixHyprland

Configuração **declarativa** para NixOS com **Hyprland**, **Home Manager** e dotfiles versionados no mesmo repositório. Objetivo: clonar numa máquina nova (ou após formatação), apontar o flake para `/etc/nixos` e instalar/reconstruir com Nix.

O caminho **`repoRoot` está fixo em `/etc/nixos`** no [flake.nix](flake.nix): os symlinks do Home Manager (`mkOutOfStoreSymlink`) precisam de um directório real no disco, não da cópia na Nix store. Mantém o clone em `/etc/nixos` (fluxo habitual do NixOS) ou cria um symlink `sudo ln -sfn /caminho/do/teu/clone /etc/nixos` para desenvolver doutro sítio.

---

## Instalação em máquina nova

### Particionamento e montagem (live USB)

1. Partição UEFI (~512 MB, vfat) e resto para `/` (por exemplo **F2FS** ou o que usares no `hardware-configuration.nix`).
2. Montagem típica:

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

(Se usares UUID, monta com `/dev/disk/by-uuid/...` conforme `blkid`.)

### Clonar este repositório

Durante a instalação a partir da ISO, o sítio usual é `/mnt/etc/nixos`:

```bash
mkdir -p /mnt/etc/nixos
git clone https://github.com/SEU-USUARIO/nixHyprland.git /mnt/etc/nixos
cd /mnt/etc/nixos
```

Substitui a URL pelo teu remoto. Depois do primeiro boot, o mesmo conteúdo fica em `/etc/nixos`.

### Hardware

Gera ou actualiza o módulo de hardware **nesta** máquina:

```bash
nixos-generate-config --root /mnt --show-hardware-config > hosts/alice-nixos/hardware-configuration.nix
```

Revisa o ficheiro (discos, kernel, filesystems) e funde com o que já existia no repo se precisares.

### Instalar

```bash
cd /mnt/etc/nixos
nixos-install --flake .#alice-nixos
```

Define a password de `root` quando pedir, reinicia e entra com o utilizador `alice` (Home Manager já vem pelo flake).

---

## Dia a dia

### Adicionar um programa

1. Utilizador: edita [modules/home/packages-home.nix](modules/home/packages-home.nix).
2. Sistema: edita [modules/nixos/packages-system.nix](modules/nixos/packages-system.nix).
3. Procura o atributo exacto em [search.nixos.org](https://search.nixos.org/packages).
4. Aplica:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#alice-nixos
```

(Se já estás em `/etc/nixos`: `sudo nixos-rebuild switch --flake .#alice-nixos`.)

### Actualizar inputs

```bash
cd /etc/nixos
nix flake update
sudo nixos-rebuild switch --flake .#alice-nixos
```

Para só um input: `nix flake lock --update-input nixpkgs`.

### Testar um pacote sem instalar

```bash
nix shell nixpkgs#nome-do-pacote
```

### Rollback

Se uma geração não arranca bem: no menu de arranque escolhe uma geração anterior; depois corrige os `.nix` e volta a correr `nixos-rebuild switch`.

---

## Estrutura do repositório

| Caminho | Função |
|---------|--------|
| [flake.nix](flake.nix) | Inputs (`nixpkgs`, `home-manager`) e `nixosConfigurations.alice-nixos`. |
| [hosts/alice-nixos/](hosts/alice-nixos/) | Hostname, discos, imports de hardware e caches. |
| [modules/nixos/](modules/nixos/) | Sistema: Hyprland, GPU AMD, Docker, PipeWire, kernel Zen, Flatpak (serviço), etc. |
| [modules/home/](modules/home/) | Home Manager: pacotes do utilizador, zsh, symlinks para `config/` e `local/share/`. |
| [home/alice/home.nix](home/alice/home.nix) | Entrada Home Manager para `alice`. |
| [config/](config/) | Espelha `~/.config/` — Hyprland, kitty, rofi, GTK, Qt, Kvantum, etc. |
| [local/share/](local/share/) | Esquemas de cores e temas de syntax highlighting (ligados via HM). |
| [home/](home/) | Ficheiros em `$HOME` / fragmentos referenciados pelo zsh (ex.: [home/zshrc.d/](home/zshrc.d/)). |

---

## Hyprland e theming

- Ficheiro principal: [config/hypr/hyprland.conf](config/hypr/hyprland.conf).
- Regras de janelas modularizadas em [config/hypr/hyprland/windowrules/](config/hypr/hyprland/windowrules/) (`general`, `floating`, `layerrules`, workspaces especiais/numerados).
- **GTK**: [config/gtk-3.0/](config/gtk-3.0/), [config/gtk-4.0/](config/gtk-4.0/).
- **Qt**: [config/qt5ct/](config/qt5ct/), [config/qt6ct/](config/qt6ct/), [config/Kvantum/](config/Kvantum/).
- Variáveis de sessão (Wayland, Qt, cursor): [modules/home/session-variables.nix](modules/home/session-variables.nix) e [config/hypr/hyprland/env.conf](config/hypr/hyprland/env.conf) onde aplicável.

---

## Flatpaks (Flathub)

Instalados na activação do Home Manager ([modules/home/flatpak-user.nix](modules/home/flatpak-user.nix)): DataGrip, Spotify, Stremio, ProtonPlus, Mission Center, qBittorrent. Adiciona IDs ao `for app in \` se precisares de mais apps.

---

## Editar dotfiles

Tudo está num **único** repositório Git. Os ficheiros em `config/` e `local/share/` são ligados por symlinks para `/etc/nixos/...`; podes editar directamente. Quando mudas **módulos Nix** (pacotes, opções de sistema), corre `nixos-rebuild switch`. Para histórico limpo: `git pull`, revisa, rebuild.

---

## Limpeza da store

Com cuidado (remove gerações não referenciadas):

```bash
sudo nix-collect-garbage -d
```

---

## Caches binários

Configurados em [hosts/alice-nixos/configuration.nix](hosts/alice-nixos/configuration.nix): `cache.nixos.org` e `nix-community.cachix.org`.

## Kernel

O módulo [modules/nixos/kernel-zen.nix](modules/nixos/kernel-zen.nix) usa `linuxPackages_zen`. Para o kernel por omissão, remove o import desse ficheiro em `configuration.nix`.
