{ pkgs, pkgs-hyprland, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Versão travada em 0.54.3 via input nixpkgs-hyprland no flake.nix.
    # Para atualizar: nix flake update nixpkgs-hyprland && sudo nixos-rebuild switch
    package = pkgs-hyprland.hyprland;
    portalPackage = pkgs-hyprland.xdg-desktop-portal-hyprland;
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
