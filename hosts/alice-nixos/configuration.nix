# NixOS host: alice-nixos
{
  config,
  pkgs,
  lib,
  repoRoot,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/kernel-zen.nix
    ../../modules/nixos/amd-gpu.nix
    ../../modules/nixos/hyprland-system.nix
    ../../modules/nixos/packages-system.nix
    ../../modules/nixos/services.nix
    ../../modules/nixos/flatpak.nix
  ];

  networking.hostName = "alice-nixos";

  time.timeZone = lib.mkDefault "America/Sao_Paulo";
  i18n.defaultLocale = lib.mkDefault "pt_BR.UTF-8";

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  users.users.alice = {
    isNormalUser = true;
    description = "alice";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit repoRoot; };
  home-manager.users.alice = import ../../home/alice/home.nix;

  system.stateVersion = "25.05";
}
