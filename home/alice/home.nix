{ ... }:

{
  imports = [
    ../../modules/home/session-variables.nix
    ../../modules/home/packages-home.nix
    ../../modules/home/zsh.nix
    ../../modules/home/audio-mirror.nix
    ../../modules/home/hypr-user-services.nix
    ../../modules/home/xdg-config.nix
    ../../modules/home/xdg-data.nix
    ../../modules/home/flatpak-user.nix
    ../../modules/home/discord-canary-flatpak.nix
  ];

  home.username = "alice";
  home.homeDirectory = "/home/alice";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
