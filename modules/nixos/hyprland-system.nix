{ pkgs, pkgs-hyprland, ... }:

let
  # Caminho relativo a este ficheiro → entra na store com o flake (sandbox).
  pr13790Patch = ../../patches/hyprland-pr13790-ignore-tiled-client-maximize.patch;

  # PR #13790 (ainda não mergeado no upstream): ignorar maximize do *cliente*
  # para janelas em tile — corrige Chromium ao sair de HTML5 fullscreen (#13322).
  # O `suppress_event maximize` nem sempre cobre o mesmo caminho Wayland.
  hyprlandPatched = pkgs-hyprland.hyprland.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ pr13790Patch ];
  });
in
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Versão travada em 0.54.3 via input nixpkgs-hyprland no flake.nix.
    # Para atualizar: nix flake update nixpkgs-hyprland && sudo nixos-rebuild switch
    package = hyprlandPatched;
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
