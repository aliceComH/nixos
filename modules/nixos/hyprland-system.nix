{ pkgs, pkgs-hyprland, ... }:

{

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs-hyprland.hyprland;
    portalPackage = pkgs-hyprland.xdg-desktop-portal-hyprland;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "0";
  };

  # Mantemos os portais explícitos para evitar regressões de screen share.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  xdg.portal.config = {
    common.default = [
      "hyprland"
      "gtk"
    ];
    hyprland.default = [
      "hyprland"
      "gtk"
    ];
  };
}
