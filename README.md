# dotfiles

Configurações pessoais para **Fedora 43 + Hyprland**.

---

## O que tem aqui

| Pasta / Arquivo | O que é |
|---|---|
| `config/` | Espelha `~/.config/` — Hyprland, GTK, Qt, Kvantum, kitty, rofi, fastfetch, starship, etc. |
| `local/` | Espelha `~/.local/share/` — color-schemes e syntax-highlighting do KDE |
| `home/` | Dotfiles soltos em `$HOME` — `.zshrc` e `zshrc.d/` |
| `system/` | Arquivos customizados em `/etc/` — autologin no tty1 e overdrive da GPU AMD |
| `install.sh` | Setup completo para uma máquina nova |
| `sync.sh` | Backup/restore bidirecional (sistema ↔ repo) |

---

## Scripts

### `sync.sh` — bidirecional

```bash
./sync.sh pull   # sistema → repo
./sync.sh push   # repo → sistema
```

**`pull`** — copia tudo do sistema para dentro do repo. Use sempre antes de fazer `git commit`, para garantir que o repo reflete o estado atual do seu sistema.

**`push`** — copia tudo do repo para o sistema. Use após clonar o repo numa máquina nova ou após uma formatação.

> **Sobre o `sudo`:** os arquivos de usuário (`~/.config/`, `~/.local/`, `~/.zshrc`) são copiados sem privilégios elevados. Os 2 arquivos em `system/etc/` precisam ir para `/etc/`, que pertence ao root — por isso o script usa `sudo` **apenas** para esses 2 arquivos. O terminal vai pedir sua senha uma única vez.

---

### `install.sh` — máquina nova

```bash
./install.sh
```

Executa na ordem:

1. Habilita RPM Fusion (free + nonfree)
2. Habilita Copr: `solopasha/hyprland`, `ilyaz/LACT`, `peterwu/rendezvous`
3. Adiciona repos externos: VS Code, Docker CE, Yarn, Cursor IDE
4. Instala todos os pacotes DNF, um por linha
5. Instala todos os Flatpaks do Flathub
6. Chama `./sync.sh push` para aplicar todas as configs

---

## Workflows

### Workflow diário — manter o GitHub em dia

Após editar qualquer arquivo de configuração no sistema:

```
./sync.sh pull
git add .
git commit -m "descrição da mudança"
git push
```

### Workflow de formatação / máquina nova

```bash
git clone https://github.com/SEU_USUARIO/dotfiles
cd dotfiles
./install.sh
# reiniciar após a conclusão
```

---

## Detalhes das configs

### Hyprland

Arquivo principal: `config/hypr/hyprland.conf`

As windowrules estão modularizadas em `config/hypr/hyprland/windowrules/`:

| Arquivo | Conteúdo |
|---|---|
| `general.conf` | `noblur` e `opacity` global de todas as apps |
| `floating.conf` | Regras `float`, `size`, `center`, PiP, `tile` |
| `layerrules.conf` | Todos os `layerrule` (AGS, rofi, wlogout, etc.) |
| `workspace-special.conf` | `special:stash` — Spotify, SVPManager, Steam |
| `workspace-4-social.conf` | Discord e steamwebhelper → workspace 4 |
| `workspace-5-gaming.conf` | Steam apps, Dota2, Albion, gamescope → workspace 5 |
| `workspace-6-media.conf` | Stremio e mpv → workspace 6 |

### Theming (GTK + Qt)

- **GTK 3/4**: `config/gtk-3.0/` e `config/gtk-4.0/` com `settings.ini` e `gtk.css`
- **Qt5**: `config/qt5ct/` com `qt5ct.conf` e color scheme
- **Qt6**: `config/qt6ct/` com `qt6ct.conf` e color scheme
- **Kvantum**: `config/Kvantum/` com temas Colloid e MaterialAdw
- **Variáveis de ambiente**: `config/environment.d/` com `QT_QPA_PLATFORMTHEME`, `QT_STYLE_OVERRIDE`

### Configs de sistema (`system/`)

Apenas arquivos que são customizações reais — não gerenciados por pacotes:

**`system/etc/systemd/system/getty@tty1.service.d/autologin.conf`**
Drop-in do systemd que configura autologin automático no tty1 para o usuário `alice`.

**`system/etc/modprobe.d/99-amdgpu-overdrive.conf`**
Habilita overdrive na GPU AMD (`ppfeaturemask=0xFFF7FFFF`) para uso com o LACT.

### Shell

- `.zshrc` principal em `home/.zshrc`
- Fragmentos em `home/zshrc.d/` (auto-Hypr, shortcuts)
- Plugins usados: `zsh-autosuggestions`, `zsh-syntax-highlighting` (instalados via dnf)

### KDE color schemes

Em `local/share/color-schemes/` — 8 variações do MaterialYou (dark/light com variantes de titlebar).

---

## Pacotes instalados

### Flatpaks (Flathub)

| App | ID |
|---|---|
| Discord | `com.discordapp.Discord` |
| JetBrains DataGrip | `com.jetbrains.DataGrip` |
| Spotify | `com.spotify.Client` |
| Stremio | `com.stremio.Stremio` |
| ProtonPlus | `com.vysp3r.ProtonPlus` |
| Mission Center | `io.missioncenter.MissionCenter` |
| qBittorrent | `org.qbittorrent.qBittorrent` |

### Repos Copr habilitados

| Copr | Para |
|---|---|
| `solopasha/hyprland` | Hyprland e utilitários atualizados |
| `ilyaz/LACT` | LACT (controle da GPU AMD) |
| `peterwu/rendezvous` | Bibata cursor themes |

### Repos externos (`.repo`)

| Repo | Para |
|---|---|
| Docker CE | `docker-ce`, `docker-ce-cli`, plugins |
| VS Code | `code` |
| Cursor IDE | `cursor` |
| Yarn | `yarn` |
