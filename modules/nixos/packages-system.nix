# Pacotes de sistema (PATH global). Flatpaks: modules/home/flatpak-user.nix
{ pkgs, ... }:

{
  environment.systemPackages =
    (with pkgs; [
    coreutils
    gettext
    findutils
    gnugrep
    git
    vim
    nano
    wget
    curl
    rsync
    socat
    lsof
    jq
    fzf
    btop
    fastfetch
    wev
    firefox
    v4l-utils
    nvme-cli
    pavucontrol
    gnome-calculator
    gnome-disk-utility
    file-roller
    pkgs.thunar
    pkgs.thunar-archive-plugin
    pkgs.thunar-volman
    rofi
    rofimoji
    kitty
    mpv
    imv
    hyprpaper
    hyprshot
    lact
    protontricks
    winetricks
    lutris
    code-cursor
    vscode
    go
    rustc
    cargo
    yarn
    openssl
    pkg-config
    vulkan-tools
    libcanberra-gtk3
    imagemagick
    tesseract
    vapoursynth
    vapoursynth-mvtools
    python3Packages.vapoursynth
    papirus-icon-theme
    bibata-cursors
    font-awesome
    ])
    ++ (with pkgs.libsForQt5; [ qt5ct ])
    ++ [ pkgs.qt6Packages.qt6ct ];
  # Kvantum: em nixpkgs recente o atributo mudou de sítio; se precisares do binário,
  # corre `nix search nixpkgs kvantum` e acrescenta aqui o attr correcto.
}
