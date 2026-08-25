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
    fd                 # busca rápida no terminal (alternativa ao find)
    ripgrep            # busca de conteúdo rápida no terminal
    p7zip              # suporte a 7z/zip/rar
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
      buildInputs = [ pkgs.makeWrapper pkgs.luajitPackages.luasocket ];
      postBuild = ''
        wrapProgram $out/bin/mpv \
          --prefix LUA_PATH ";" "${pkgs.luajitPackages.luasocket}/share/lua/5.1/?.lua;${pkgs.luajitPackages.luasocket}/share/lua/5.1/?/init.lua" \
          --prefix LUA_CPATH ";" "${pkgs.luajitPackages.luasocket}/lib/lua/5.1/?.so" \
          --run 'for p in $(pgrep -x mpv); do [ "$p" != "$$" ] && kill -9 "$p" 2>/dev/null || true; done'
      '';
    })
    imv
    hyprpaper
    hyprshot
    protontricks
    winetricks
    (pkgs.symlinkJoin {
      name = "osu-lazer-fast";
      paths = [ pkgs-osu.osu-lazer-bin ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        # Varre a pasta bin e injeta prioridade alta em todos os executáveis (incluindo o "osu!")
        # NOTA: PIPEWIRE_QUANTUM foi removido — o quantum 32/48000 já é configurado
        # globalmente em services.nix (context.properties). A variável de ambiente
        # forçava renegociação do graph inteiro, conflitando com Discord/WebRTC.
        for bin in $out/bin/*; do
          wrapProgram "$bin" \
            --set PIPEWIRE_LATENCY "32/48000" \
            --set PIPEWIRE_ALSA "{ alsa.format=S32_LE alsa.channels=2 alsa.rate=48000 alsa.buffer-bytes=512 alsa.period-bytes=256 }" \
            --run 'renice -n -15 $$ >/dev/null 2>&1 || true'
        done
      '';
    })
    python3
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
    vesktop
    teamspeak6-client
    code-cursor
    ])
    ++ (with pkgs.libsForQt5; [ qt5ct ])
    ++ [ pkgs.qt6Packages.qt6ct ];
  # Kvantum: em nixpkgs recente o atributo mudou de sítio; se precisares do binário,
  # corre `nix search nixpkgs kvantum` e acrescenta aqui o attr correcto.
}
