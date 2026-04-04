#!/bin/bash
# Uso: ./sync.sh pull   → sistema para o repo (antes de commitar)
#      ./sync.sh push   → repo para o sistema (após clonar ou formatar)

set -e
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pull() {
    echo "==> Copiando configs do sistema para o repo..."

    # --- Hyprland ---
    rsync -avh --delete ~/.config/hypr/                         "$REPO/config/hypr/"

    # --- GTK ---
    rsync -avh --delete ~/.config/gtk-3.0/                      "$REPO/config/gtk-3.0/"
    rsync -avh --delete ~/.config/gtk-4.0/                      "$REPO/config/gtk-4.0/"

    # --- Qt / Kvantum ---
    rsync -avh --delete ~/.config/qt5ct/                        "$REPO/config/qt5ct/"
    rsync -avh --delete ~/.config/qt6ct/                        "$REPO/config/qt6ct/"
    rsync -avh --delete ~/.config/Kvantum/                      "$REPO/config/Kvantum/"

    # --- Terminal e ferramentas ---
    rsync -avh --delete ~/.config/kitty/                        "$REPO/config/kitty/"
    rsync -avh --delete ~/.config/fastfetch/                    "$REPO/config/fastfetch/"
    rsync -avh           ~/.config/starship.toml                "$REPO/config/starship.toml"

    # --- Launchers e portais ---
    rsync -avh --delete ~/.config/rofi/                         "$REPO/config/rofi/"
    rsync -avh --delete ~/.config/xdg-desktop-portal/           "$REPO/config/xdg-desktop-portal/"

    # --- Variáveis de ambiente e theming ---
    rsync -avh --delete ~/.config/environment.d/                "$REPO/config/environment.d/"
    rsync -avh --delete ~/.config/kde-material-you-colors/      "$REPO/config/kde-material-you-colors/"

    # --- ~/.local/share ---
    rsync -avh --delete ~/.local/share/color-schemes/           "$REPO/local/share/color-schemes/"
    rsync -avh --delete ~/.local/share/org.kde.syntax-highlighting/ \
                                                                "$REPO/local/share/org.kde.syntax-highlighting/"

    # --- Dotfiles de $HOME ---
    rsync -avh ~/.zshrc                                         "$REPO/home/.zshrc"
    rsync -avh --delete ~/.config/zshrc.d/                      "$REPO/home/zshrc.d/"

    # --- Configs de sistema (requer sudo para ler /etc/) ---
    sudo rsync -avh /etc/systemd/system/getty@tty1.service.d/   \
        "$REPO/system/etc/systemd/system/getty@tty1.service.d/"
    sudo rsync -avh /etc/modprobe.d/99-amdgpu-overdrive.conf    \
        "$REPO/system/etc/modprobe.d/"
    sudo chown -R "$USER:$USER" "$REPO/system/"

    echo ""
    echo "Pronto. Revise as mudanças com 'git diff' e faça commit:"
    echo "  git add . && git commit -m 'update configs' && git push"
}

push() {
    echo "==> Aplicando configs do repo no sistema..."

    # --- Hyprland ---
    rsync -avh "$REPO/config/hypr/"                         ~/.config/hypr/

    # --- GTK ---
    rsync -avh "$REPO/config/gtk-3.0/"                      ~/.config/gtk-3.0/
    rsync -avh "$REPO/config/gtk-4.0/"                      ~/.config/gtk-4.0/

    # --- Qt / Kvantum ---
    rsync -avh "$REPO/config/qt5ct/"                        ~/.config/qt5ct/
    rsync -avh "$REPO/config/qt6ct/"                        ~/.config/qt6ct/
    rsync -avh "$REPO/config/Kvantum/"                      ~/.config/Kvantum/

    # --- Terminal e ferramentas ---
    rsync -avh "$REPO/config/kitty/"                        ~/.config/kitty/
    rsync -avh "$REPO/config/fastfetch/"                    ~/.config/fastfetch/
    rsync -avh "$REPO/config/starship.toml"                 ~/.config/starship.toml

    # --- Launchers e portais ---
    rsync -avh "$REPO/config/rofi/"                         ~/.config/rofi/
    rsync -avh "$REPO/config/xdg-desktop-portal/"           ~/.config/xdg-desktop-portal/

    # --- Variáveis de ambiente e theming ---
    rsync -avh "$REPO/config/environment.d/"                ~/.config/environment.d/
    rsync -avh "$REPO/config/kde-material-you-colors/"      ~/.config/kde-material-you-colors/

    # --- ~/.local/share ---
    mkdir -p ~/.local/share/color-schemes ~/.local/share/org.kde.syntax-highlighting
    rsync -avh "$REPO/local/share/color-schemes/"           ~/.local/share/color-schemes/
    rsync -avh "$REPO/local/share/org.kde.syntax-highlighting/" \
                                                            ~/.local/share/org.kde.syntax-highlighting/

    # --- Dotfiles de $HOME ---
    rsync -avh "$REPO/home/.zshrc"                          ~/.zshrc
    rsync -avh "$REPO/home/zshrc.d/"                        ~/.config/zshrc.d/

    # --- Configs de sistema (requer sudo para escrever em /etc/) ---
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
    sudo rsync -avh "$REPO/system/etc/systemd/system/getty@tty1.service.d/" \
        /etc/systemd/system/getty@tty1.service.d/
    sudo rsync -avh "$REPO/system/etc/modprobe.d/99-amdgpu-overdrive.conf" \
        /etc/modprobe.d/
    sudo systemctl daemon-reload

    echo ""
    echo "Pronto. Reinicie o sistema para aplicar as mudanças de /etc/."
}

case "$1" in
    pull) pull ;;
    push) push ;;
    *)
        echo "Uso: $0 [pull|push]"
        echo "  pull  → copia configs do sistema para o repo (use antes de commitar)"
        echo "  push  → aplica configs do repo no sistema (use após clonar ou formatar)"
        exit 1
        ;;
esac
