# Traduz env.conf do Hyprland + Wayland/Electron (preferir aqui em vez de só env = no Hyprland).
{ pkgs, ... }:

{
  # Garante o cursor para apps Wayland e XWayland (ex.: Steam).
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 48;
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
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "48";
    NIXOS_OZONE_WL = "1";
    # PipeWire em low-latency (quantum menor para reduzir atraso de audio).
    PIPEWIRE_LATENCY = "128/48000";
  };
}
