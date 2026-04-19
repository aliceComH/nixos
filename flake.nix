{
  description = "nixHyprland — NixOS + Home Manager + Hyprland (alice-nixos)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      # Checkout deve viver em /etc/nixos para symlinks mkOutOfStoreSymlink apontarem para ficheiros editáveis.
      repoRoot = "/etc/nixos";
    in
    {
      nixosConfigurations.alice-nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit repoRoot; };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/alice-nixos/configuration.nix
        ];
      };
    };
}
