# Pacotes de sistema (PATH global). Flatpaks: modules/home/flatpak-user.nix
{ pkgs, pkgs-osu, ... }:

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
    google-chrome
    wootility
    v4l-utils
    nvme-cli
    pavucontrol
    gnome-calculator
    gnome-disk-utility
    file-roller
    pkgs.thunar
    pkgs.thunar-archive-plugin
    pkgs.thunar-volman
    nautilus
    traceroute
    rofi
    rofimoji
    kitty
    playerctl
    s-tui
    (pkgs.symlinkJoin {
      name = "mpv-single-instance";
      paths = [
        (pkgs.mpv.override {
          mpv-unwrapped = pkgs.mpv-unwrapped.override {
            vapoursynthSupport = true;
            vapoursynth = pkgs.vapoursynth.withPlugins [
              pkgs.vapoursynth-mvtools
              (pkgs.callPackage ../../pkgs/vapoursynth-rife-ncnn-vulkan/package.nix {})
            ];
          };
        })
      ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/mpv \
          --run 'for p in $(pgrep -x mpv); do [ "$p" != "$$" ] && kill -9 "$p" 2>/dev/null || true; done'
      '';
    })
    imv
    hyprpaper
    hyprshot
    lact
    protontricks
    winetricks
    (pkgs.symlinkJoin {
      name = "osu-lazer-fast";
      paths = [ pkgs-osu.osu-lazer-bin ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        # Varre a pasta bin e injeta a latência extrema em todos os executáveis (incluindo o "osu!")
        for bin in $out/bin/*; do
          wrapProgram "$bin" \
            --set PIPEWIRE_LATENCY "64/48000"
        done
      '';
    })
    sublime4
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
    papirus-icon-theme
    font-awesome
    cloudflare-warp
    vesktop
    ])
    ++ (with pkgs.libsForQt5; [ qt5ct ])
    ++ [ pkgs.qt6Packages.qt6ct ];
  # Kvantum: em nixpkgs recente o atributo mudou de sítio; se precisares do binário,
  # corre `nix search nixpkgs kvantum` e acrescenta aqui o attr correcto.
}
