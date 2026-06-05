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

### LLM local (Ollama + Open WebUI + Qwen)

Este repositório já inclui módulos para LLM em:
- [modules/nixos/llm/ollama.nix](modules/nixos/llm/ollama.nix)

Depois de aplicar a configuração:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#alice-nixos
```

#### Arranque no boot

O **Ollama não sobe automaticamente** no boot (o `multi-user.target` não puxa o serviço). Usa os comandos abaixo ou os atalhos do Hyprland.

#### Scripts `llm-start` e `llm-stop` (recomendado)

Estão no `PATH` do sistema (definidos em `llm/ollama.nix`):

```bash
llm-start   # sobe ollama + open-webui (cria o container na primeira vez)
llm-stop    # para open-webui + ollama
```

Na **mesma máquina**: `http://localhost:3000` (Open WebUI). Noutro PC na **LAN**: `http://IP-DESTA-MAQUINA:3000`.

#### Rede local (LAN) — o que está exposto e quando

Ideia simples: **só existe “coisa na rede” enquanto o stack estiver ligado** (`llm-start`). Quando fazes `llm-stop`, o Ollama para de escutar e o container da WebUI para — **ninguém na rede consegue ligar** a esses portos até voltares a subir tudo.

1. **Ollama (API, modelos)**  
   - Escuta em **todas as interfaces** na porta **11434** (`0.0.0.0:11434`).  
   - O firewall do NixOS **abre o TCP 11434** para a LAN (e tecnicamente para qualquer interface; na prática o teu router em casa não expõe isto à Internet a não ser que faças **port forward** — não recomendado).  
   - Noutro dispositivo na mesma Wi‑Fi/cabo: no browser ou no Continue/Cursor usa como base da API algo como `http://IP-DESTA-MAQUINA:11434` (ex.: listar modelos: `http://IP-DESTA-MAQUINA:11434/api/tags`).  
   - **Não há palavra-passe** nesta API na LAN — trata a tua rede como zona de confiança.

2. **Open WebUI (interface web)**  
   - O `llm-start` publica o container em **`0.0.0.0:3000`** → qualquer PC na LAN pode abrir `http://IP-DESTA-MAQUINA:3000`.  
   - O firewall **abre o TCP 3000**.  
   - O browser noutro PC fala com a WebUI nesse IP; a WebUI, por dentro do Docker, continua a falar com o Ollama no host via `OLLAMA_BASE_URL=http://172.17.0.1:11434`.

3. **Descobrir o IP desta máquina na LAN**  

```bash
ip -brief addr
# ou, por exemplo:
hostname -I
```

4. **Se já tinhas criado o container com `-p 127.0.0.1:3000`** (só localhost), após `nixos-rebuild switch` tens de **recriar** o container uma vez para passar a escutar na LAN:

```bash
llm-stop
docker rm -f open-webui
llm-start
```

5. **Internet (WAN)**  
   Este setup está intencionalmente **LAN-only**. Não abras **11434** nem **3000** no router para a Internet.

#### Hyprland (submaps `reset` e `auxiliar`, não no `gaming`)

Em [config/hypr/hyprland/keybinds.conf](config/hypr/hyprland/keybinds.conf):

- **SUPER+SHIFT+F1** — `llm-start`
- **SUPER+SHIFT+F2** — `llm-stop`

No submap **gaming** estes atalhos não existem de propósito.

#### Manual (equivalente aos scripts)

```bash
sudo systemctl start ollama
docker start open-webui || docker run -d --name open-webui --restart unless-stopped \
  -p 0.0.0.0:3000:8080 \
  -e OLLAMA_BASE_URL=http://172.17.0.1:11434 \
  ghcr.io/open-webui/open-webui:main
```

```bash
docker stop open-webui
sudo systemctl stop ollama
```

#### Verificar estado

```bash
systemctl status ollama --no-pager
docker ps --filter name=open-webui
docker ps --filter name=searxng
curl http://127.0.0.1:11434/api/tags
curl "http://127.0.0.1:8080/search?q=teste&format=json"
```

#### Web Search com SearXNG

O stack LLM também sobe o container `searxng` para alimentar a busca web da Open WebUI:

- `llm-start` garante a rede Docker `llm-stack` e sobe `searxng` (localhost `:8080`) antes da Open WebUI.
- A Open WebUI é iniciada com:
  - `ENABLE_WEB_SEARCH=True`
  - `WEB_SEARCH_ENGINE=searxng`
  - `SEARXNG_QUERY_URL=http://searxng:8080/search?q=<query>&format=json`
- O SearXNG fica publicado só em `127.0.0.1:8080` (não em LAN), enquanto a Open WebUI continua em `0.0.0.0:3000`.
- O `llm-start` espera até `http://127.0.0.1:3000/health` devolver HTTP 200 (primeiro arranque pode levar até alguns minutos por migrações / downloads).

Smoke test rápido:

```bash
llm-start
curl "http://127.0.0.1:8080/search?q=nixos&format=json"
docker logs --tail 80 searxng
docker logs --tail 80 open-webui
```

No browser (Open WebUI):

1. Abre `http://127.0.0.1:3000` (preferível a `localhost`: no Linux o nome costuma resolver primeiro para IPv6 `[::1]`, mas o Docker publica apenas em IPv4 neste mapeamento, o que causa falhas ou mensagens enganadoras).
2. Em `Admin Panel -> Settings -> Web Search`, confirma `searxng`.
3. Numa conversa, ativa Web Search no botão de integrações.

Troubleshooting:

- Mensagens tipo “internal error” logo após `llm-start`: espera até o comando terminar; confirma com `curl -sSI http://127.0.0.1:3000/health` (deve devolver HTTP 200).
- Se mesmo com `/health` em 200 o browser falhar, testa sempre `127.0.0.1` em vez de `localhost`.
- Se a busca devolver erro 403/500, valida se o SearXNG responde em JSON (`format=json`).
- Se a Open WebUI não “ver” o SearXNG, confirma que ambos estão na rede `llm-stack`:
  - `docker inspect open-webui`
  - `docker inspect searxng`
- Se alterares variáveis de Web Search manualmente, remove e recria o container da Open WebUI:
  - `docker rm -f open-webui && llm-start`

#### Modelo Qwen

O módulo já declara:

```nix
services.ollama.loadModels = [ "qwen2.5-coder:14b" ];
```

Para testar rapidamente (com o serviço **já** a correr):

```bash
ollama run qwen2.5-coder:14b
```

#### Comandos úteis

```bash
# Logs do Ollama
journalctl -u ollama -f

# Logs da Open WebUI
docker logs -f open-webui

# Logs do SearXNG
docker logs -f searxng

# Remover e recriar Open WebUI (se necessário)
docker rm -f open-webui
```

#### Busca web para outros clientes (além da Open WebUI)

Clientes que falam diretamente com a API do Ollama não ganham busca web automaticamente. Para suportar esse cenário, adiciona uma camada de agente/gateway com tools:

1. Cliente envia prompt para o gateway (não direto ao Ollama).
2. Gateway decide quando chamar o SearXNG (`/search?...format=json`).
3. Gateway injeta contexto no prompt final e só então chama o Ollama.
4. Resposta volta ao cliente com/sem citações de fontes.

Implementação incremental recomendada:

- Fase 1: Open WebUI + SearXNG (já funcional para uso humano via UI).
- Fase 2: serviço leve (ex.: FastAPI) com endpoint compatível com os clientes principais.
- Fase 3: políticas de segurança (timeout, domínio permitido, rate limit e cache).

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

Para só um input: `nix flake update nixpkgs`.

### Referência rápida de actualizações

| Acção | Comando | O que muda |
|---|---|---|
| Aplicar config actual | `sudo nixos-rebuild switch` | Nada nas versões |
| Actualizar tudo | `nix flake update && sudo nixos-rebuild switch` | `flake.lock` → novas versões |
| Actualizar só nixpkgs | `nix flake update nixpkgs && sudo nixos-rebuild switch` | Só nixpkgs |
| Actualizar Hyprland | `nix flake update nixpkgs-hyprland && sudo nixos-rebuild switch` | Só Hyprland |
| **Actualizar osu-lazer** | `nix flake update nixpkgs-osu && sudo nixos-rebuild switch` | **Só osu-lazer** |
| Voltar versão anterior | `sudo nixos-rebuild switch --rollback` | Geração anterior do sistema |

### Actualizar o osu-lazer (independente)

O osu-lazer usa um input **`nixpkgs-osu`** separado no [flake.nix](flake.nix), o que significa que podes actualizar a versão dele **sem mexer** no nixpkgs principal, Hyprland, ou qualquer outro pacote do sistema.

```bash
cd /etc/nixos
nix flake update nixpkgs-osu
sudo nixos-rebuild switch --flake .#alice-nixos
```

Isto avança o `nixpkgs-osu` para o HEAD do `nixos-unstable`, puxando a versão mais recente do `osu-lazer-bin` disponível nesse commit. Todo o resto do sistema fica intocado.

> **Nota:** o wrapper `osu-lazer-fast` com `PIPEWIRE_LATENCY="64/48000"` continua a ser aplicado automaticamente sobre o binário vindo do `nixpkgs-osu`.

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
| [flake.nix](flake.nix) | Inputs (`nixpkgs`, `nixpkgs-osu`, `home-manager`) e `nixosConfigurations.alice-nixos`. |
| [hosts/alice-nixos/](hosts/alice-nixos/) | Hostname, discos, imports de hardware e caches. |
| [modules/nixos/](modules/nixos/) | Sistema: Hyprland, GPU AMD, Docker, PipeWire, kernel Zen, Flatpak (serviço), etc. |
| [modules/home/](modules/home/) | Home Manager: pacotes do utilizador, zsh, symlinks para `config/` e `local/share/`. |
| [home/alice/home.nix](home/alice/home.nix) | Entrada Home Manager para `alice`. |
| [config/](config/) | Espelha `~/.config/` — Hyprland, kitty, rofi, Cursor (`User/settings.json`, `keybindings.json`), GTK, Qt, Kvantum, etc. |
| [wallpapers/](wallpapers/) | Imagem fixa **`1.jpeg`** para o hyprpaper (ver `set_wallpaper.sh`). |
| [local/share/](local/share/) | Esquemas de cores e temas de syntax highlighting (ligados via HM). |
| [home/](home/) | Ficheiros em `$HOME` no repositório; o zsh é configurado em [modules/home/zsh.nix](modules/home/zsh.nix) (não uses `home/.zshrc` como fonte ativa). |

---

## Versões travadas (pinning)

O Hyprland está **travado** numa versão específica e **não actualiza** com `nix flake update`. Isso é feito através de um input separado no `flake.nix`:

```nix
# flake.nix
nixpkgs-hyprland.url = "github:NixOS/nixpkgs/COMMIT_HASH";
nixpkgs-hyprland.flake = false;
```

O commit aponta para o nixpkgs exacto onde a versão desejada do Hyprland está disponível. O módulo [`modules/nixos/hyprland-system.nix`](modules/nixos/hyprland-system.nix) consome esse input via `pkgs-hyprland.hyprland` e `pkgs-hyprland.xdg-desktop-portal-hyprland`.

**Para actualizar o Hyprland manualmente:**

1. Vai a [search.nixos.org/packages](https://search.nixos.org/packages) e encontra o commit do nixpkgs que tem a versão que queres.
2. Altera o hash em `flake.nix`:
   ```nix
   nixpkgs-hyprland.url = "github:NixOS/nixpkgs/NOVO_COMMIT_HASH";
   ```
3. Aplica:
   ```bash
   sudo nixos-rebuild switch
   ```
   
   Ou usa o atalho que actualiza o input automaticamente para o HEAD do unstable:
   ```bash
   nix flake update nixpkgs-hyprland && sudo nixos-rebuild switch
   ```

### osu-lazer (input independente)

O **osu-lazer** também tem um input separado (`nixpkgs-osu`), mas ao contrário do Hyprland, segue o `nixos-unstable` em vez de estar travado num commit fixo. Isto permite actualizar o osu a qualquer momento sem arrastar o resto do sistema:

```bash
nix flake update nixpkgs-osu && sudo nixos-rebuild switch
```

Se quiseres travar o osu-lazer numa versão específica (por exemplo, para evitar regressões), altera o input para um commit fixo:

```nix
nixpkgs-osu.url = "github:NixOS/nixpkgs/COMMIT_HASH_COM_VERSAO_DESEJADA";
```

---

## Hyprland e theming

- Ficheiro principal: [config/hypr/hyprland.conf](config/hypr/hyprland.conf).
- **Wallpaper (hyprpaper 0.8+)**: ficheiro fixo [wallpapers/1.jpeg](wallpapers/1.jpeg); [config/hypr/hyprland/scripts/set_wallpaper.sh](config/hypr/hyprland/scripts/set_wallpaper.sh) gera `~/.local/state/nixos-wallpaper/hyprpaper.conf` em **hyprlang** (`wallpaper { monitor = … path = … }`). Arranque: `hyprpaper -c` em [config/hypr/hyprland/execs.conf](config/hypr/hyprland/execs.conf). Detalhes em [wallpapers/README.md](wallpapers/README.md).
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

O módulo [modules/nixos/kernel-7-rt-oriented.nix](modules/nixos/kernel-7-rt-oriented.nix) usa `linux_7_0` com tuning agressivo de baixa latência (RT-oriented) e cria uma specialisation de fallback `zen-fallback` com `linuxPackages_zen`.

Se quiser voltar ao perfil Zen por omissão, troca o import em `configuration.nix` para [modules/nixos/kernel-zen.nix](modules/nixos/kernel-zen.nix).

Benchmark recomendado após reboot: [KERNEL_BENCHMARK_RT_ORIENTED.md](KERNEL_BENCHMARK_RT_ORIENTED.md).
