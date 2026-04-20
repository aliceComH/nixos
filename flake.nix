{
  description = "nixHyprland — NixOS + Home Manager + Hyprland (alice-nixos)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nixpkgs travado no commit que fornece Hyprland 0.54.3.
    # Atualizar manualmente com: nix flake update nixpkgs-hyprland
    nixpkgs-hyprland.url = "github:NixOS/nixpkgs/4bd9165a9165d7b5e33ae57f3eecbcb28fb231c9";
    nixpkgs-hyprland.flake = false;

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, nixpkgs-hyprland, home-manager, ... }:
    let
      system = "x86_64-linux";
      # Checkout deve viver em /etc/nixos para symlinks mkOutOfStoreSymlink apontarem para ficheiros editáveis.
      repoRoot = "/etc/nixos";
      pkgs-hyprland = import nixpkgs-hyprland { inherit system; config.allowUnfree = true; };
    in
    {
      nixosConfigurations.alice-nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit repoRoot pkgs-hyprland; };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/alice-nixos/configuration.nix
        ];
      };
    };
}
