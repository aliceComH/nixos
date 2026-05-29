{ pkgs, ... }:

let
  ghostlineCursor = pkgs.stdenv.mkDerivation {
    pname = "ghostline-cursor-theme";
    version = "git";

    src = pkgs.fetchFromGitHub {
      owner = "patinhooh";
      repo = "ghostline-cursor-theme";
      rev = "main";
      # Se der erro de "hash mismatch", copie o hash que o terminal der e coloque nestas aspas!
      hash = "sha256-emllRxawCKiTSseCuoAARs2bG7niyvJU762Y4bDijOQ="; 
    };

    installPhase = ''
      mkdir -p $out/share/icons/ghostline
      cp -r linux/dark/* $out/share/icons/ghostline/
    '';
  };
in
{
  home.pointerCursor = {
    enable = true;
    package = ghostlineCursor; # Agora o Nix sabe quem é esse cara
    name = "ghostline";        # Nome exato da pasta que criamos ali no installPhase
    size = 32; 
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = {
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    QT_QPA_PLATFORM = "wayland";
    XDG_MENU_PREFIX = "plasma-";
    WLR_DRM_NO_ATOMIC = "0";
    WLR_NO_HARDWARE_CURSORS = "0";
    CLUTTER_BACKEND = "wayland";
    GDK_BACKEND = "wayland,x11";
    TERMINAL = "kitty -1";
    QT_QPA_PLATFORMTHEME = "gtk4";
    XCURSOR_THEME = "ghostline";
    XCURSOR_SIZE = "32";
    NIXOS_OZONE_WL = "1";
    PIPEWIRE_LATENCY = "64/48000";
  };
}
