# LACT — Linux GPU Configuration Tool (AMD/NVIDIA)
# GUI em ALT+F3 (keybinds.lua). Daemon lactd expõe controle de clock/power.
#
# O pacote do nixpkgs unstable quebra com libdisplay-info 0.4.0; usamos o
# wrapper em pkgs/lact/ que fixa libdisplay-info em 0.3.0 até o upstream
# aceitar 0.4.0 no crate Rust.
{ pkgs, ... }:

let
  lact = pkgs.callPackage ../../pkgs/lact/package.nix { };
in
{
  services.lact = {
    enable = true;
    package = lact;
  };
}
