{
  description = "nixHyprland — NixOS + Home Manager + Hyprland (alice-nixos)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    antigravity-nix.url = "github:jacopone/antigravity-nix";

    # nixpkgs travado no commit exato que tem o Hyprland 0.55
    # Para atualizar o Hyprland no futuro, precisamos mudar a hash aqui.
    nixpkgs-hyprland.url = "github:NixOS/nixpkgs/e73de5be04e0eff4190a1432b946d469c794e7b4";
    nixpkgs-hyprland.flake = false;

    # nixpkgs independente para o osu-lazer.
    # Atualizar apenas o osu: nix flake update nixpkgs-osu
    nixpkgs-osu.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # A tag @inputs captura tudo o que foi definido acima e empacota numa variável
  outputs = { self, nixpkgs, nixpkgs-hyprland, nixpkgs-osu, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      # Checkout deve viver em /etc/nixos para symlinks mkOutOfStoreSymlink apontarem para ficheiros editáveis.
      repoRoot = "/etc/nixos";
      pkgs-hyprland = import nixpkgs-hyprland { inherit system; config.allowUnfree = true; };
      pkgs-osu = import nixpkgs-osu { inherit system; config.allowUnfree = true; };
    in
    {
      nixosConfigurations.alice-nixos = nixpkgs.lib.nixosSystem {
        # Passa as variáveis para o nível do sistema NixOS
        specialArgs = { inherit repoRoot pkgs-hyprland pkgs-osu inputs; };
        
        modules = [
          home-manager.nixosModules.home-manager
          {
            # Passa a variável 'inputs' especificamente para os arquivos do Home Manager
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
          ./hosts/alice-nixos/configuration.nix
          { nixpkgs.hostPlatform = system; }
        ];
      };
    };
}
