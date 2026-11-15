# Ferramentas do sistema (PATH global): CLI, utilitários do desktop, toolchains,
# temas. Vêm do input `nixpkgs` (base), junto com kernel e drivers — grupo
# "Sistema" da Central de Updates. Ver .agents/knowledge/updates.md.
#
# Programas (apps) ficam em modules/nixos/programs.nix (input nixpkgs-apps).
# osu! fica em modules/nixos/osu.nix (input nixpkgs-osu).
# Flatpaks: modules/home/flatpak-user.nix
{ pkgs, ... }:

let
  giTypelibPkgs = with pkgs; [
    atk
    gdk-pixbuf
    glib
    gobject-introspection
    gsettings-desktop-schemas
    gtk3
    harfbuzz
    pango
  ];
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
  # GI_TYPELIB_PATH na sessão do Hyprland não actualiza sem logout.
  # wrapGApps mete os typelibs no wrapper do python.
  pythonWithGi = pkgs.stdenv.mkDerivation {
    pname = "python3-with-gi";
    inherit (pkgs.python3) version;
    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.wrapGAppsHook3
      pkgs.gobject-introspection
    ];
    buildInputs = giTypelibPkgs ++ [ pythonEnv ];
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    dontWrapGApps = true;
    installPhase = ''
      mkdir -p $out/bin
      for f in ${pythonEnv}/bin/*; do
        ln -s "$f" "$out/bin/$(basename "$f")"
      done
      rm -f $out/bin/python $out/bin/python3
      rm -f $out/bin/python3.*
    '';
    postFixup = ''
      makeWrapper ${pythonEnv}/bin/python3 $out/bin/python3 \
        "''${gappsWrapperArgs[@]}"
      ln -s python3 $out/bin/python
    '';
  };
  tools =
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
    v4l-utils
    nvme-cli
    pavucontrol
    fd                 # busca rápida no terminal (alternativa ao find)
    ripgrep            # busca de conteúdo rápida no terminal
    p7zip              # suporte a 7z/zip/rar
    traceroute
    rofi
    rofimoji
    kitty
    playerctl
    s-tui
    hyprpaper
    hyprshot
    pythonWithGi
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
    colloid-icon-theme # ícones em uso (Colloid-Dark); o Papirus fica como fallback
    adw-gtk3 # tema GTK3 que lê as cores nomeadas de config/gtk-3.0/gtk.css
    font-awesome
    ])
    ++ (with pkgs.libsForQt5; [ qt5ct ])
    ++ [ pkgs.qt6Packages.qt6ct ];
in
{
  environment.systemPackages = tools;

  # Lista exibida na Central de Updates (tools/updates/updates.py).
  local.updateGroups.ferramentas = tools;
  # Kvantum: em nixpkgs recente o atributo mudou de sítio; se precisares do binário,
  # corre `nix search nixpkgs kvantum` e acrescenta aqui o attr correcto.
}
