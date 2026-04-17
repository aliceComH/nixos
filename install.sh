#!/bin/bash
# Setup completo para uma máquina Fedora nova.
# Execute a partir da raiz do repo: ./install.sh

set -e
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo " Fedora dotfiles — instalação completa"
echo "========================================"
echo ""

# ─────────────────────────────────────────────
# [1/4] Repositórios
# ─────────────────────────────────────────────
echo "==> [1/4] Habilitando repositórios..."

# RPM Fusion (free e nonfree)
sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Copr: Hyprland atualizado
sudo dnf copr enable -y solopasha/hyprland

# Copr: LACT (AMD GPU tool)
sudo dnf copr enable -y ilyaz/LACT

# Copr: Bibata cursor themes
sudo dnf copr enable -y peterwu/rendezvous

# VS Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

# Docker CE
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Yarn
sudo curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo

# Cursor IDE
sudo sh -c 'echo -e "[cursor]\nname=Cursor IDE\nbaseurl=https://download.cursor.sh/linux/appimage/x86_64\nenabled=1\ngpgcheck=0" > /etc/yum.repos.d/cursor.repo'

# ─────────────────────────────────────────────
# [2/4] Pacotes DNF
# ─────────────────────────────────────────────
echo ""
echo "==> [2/4] Instalando pacotes DNF..."

# --- Hyprland ---
sudo dnf install -y hyprland
sudo dnf install -y hyprpaper
sudo dnf install -y hyprshot

# --- Terminal e shell ---
sudo dnf install -y kitty
sudo dnf install -y zsh
sudo dnf install -y zsh-autosuggestions
sudo dnf install -y zsh-syntax-highlighting
sudo dnf install -y btop
sudo dnf install -y fastfetch
sudo dnf install -y fzf

# --- Theming ---
sudo dnf install -y kvantum
sudo dnf install -y qt5ct
sudo dnf install -y qt6ct
sudo dnf install -y papirus-icon-theme
sudo dnf install -y bibata-cursor-themes

# --- Apps desktop ---
sudo dnf install -y Thunar
sudo dnf install -y thunar-archive-plugin
sudo dnf install -y thunar-volman
sudo dnf install -y file-roller
sudo dnf install -y rofi
sudo dnf install -y rofimoji
sudo dnf install -y pavucontrol
sudo dnf install -y gnome-calculator
sudo dnf install -y gnome-disk-utility
sudo dnf install -y mpv
sudo dnf install -y imv

# --- Gaming ---
sudo dnf install -y steam
sudo dnf install -y lutris
sudo dnf install -y protontricks
sudo dnf install -y winetricks
sudo dnf install -y lact

# --- Dev tools ---
sudo dnf install -y git
sudo dnf install -y code
sudo dnf install -y cursor
sudo dnf install -y golang
sudo dnf install -y rust
sudo dnf install -y cargo
sudo dnf install -y yarn
sudo dnf install -y docker-ce
sudo dnf install -y docker-ce-cli
sudo dnf install -y containerd.io
sudo dnf install -y docker-buildx-plugin
sudo dnf install -y docker-compose-plugin
sudo dnf install -y openssl-devel

# --- GPU / ROCm (AMD) ---
sudo dnf install -y mesa-libOpenCL
sudo dnf install -y rocm-opencl

# --- VapourSynth ---
sudo dnf install -y vapoursynth-devel
sudo dnf install -y vapoursynth-tools
sudo dnf install -y python3-vapoursynth

# --- Fontes ---
sudo dnf install -y fontawesome-fonts-all
sudo dnf install -y google-noto-emoji-fonts
sudo dnf install -y google-noto-sans-cjk-fonts
sudo dnf install -y jetbrains-mono-fonts-all

# --- Ferramentas de sistema ---
sudo dnf install -y rsync
sudo dnf install -y socat
sudo dnf install -y lsof
sudo dnf install -y wev
sudo dnf install -y v4l-utils
sudo dnf install -y nvme-cli
sudo dnf install -y tuned
sudo dnf install -y pipewire-utils
sudo dnf install -y tesseract
sudo dnf install -y tesseract-langpack-por

# ─────────────────────────────────────────────
# [3/4] Flatpaks
# ─────────────────────────────────────────────
echo ""
echo "==> [3/4] Instalando Flatpaks..."

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install -y flathub dev.vencord.Vesktop
flatpak install -y flathub com.jetbrains.DataGrip
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub com.stremio.Stremio
flatpak install -y flathub com.vysp3r.ProtonPlus
flatpak install -y flathub io.missioncenter.MissionCenter
flatpak install -y flathub org.qbittorrent.qBittorrent

# ─────────────────────────────────────────────
# [4/4] Configs
# ─────────────────────────────────────────────
echo ""
echo "==> [4/4] Aplicando configs..."

"$REPO/sync.sh" push

echo ""
echo "========================================"
echo " Instalação concluída!"
echo " Reinicie o sistema para aplicar tudo."
echo "========================================"
