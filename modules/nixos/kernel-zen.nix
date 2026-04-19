# Kernel Linux Zen do nixpkgs (low-latency, adequado a desktop/gaming).
# Para o kernel padrão do NixOS, comenta este import em `hosts/alice-nixos/configuration.nix`.
{ lib, pkgs, ... }:

{
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
}
