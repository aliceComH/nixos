{ pkgs, ... }:

{
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Original-Ice";
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
    XCURSOR_THEME = "Bibata-Original-Ice";
    XCURSOR_SIZE = "32";
    NIXOS_OZONE_WL = "1";
  };
}
