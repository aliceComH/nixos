{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "0";
  };

  # programs.hyprland já liga xdg.portal e o portal Hyprland; acrescentamos GTK para diálogos etc.
  xdg.portal.extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];

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
