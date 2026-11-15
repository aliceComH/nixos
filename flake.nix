{
  description = "nixHyprland — NixOS + Home Manager + Hyprland (alice-nixos)";

  inputs = {
    # ── Grupos de atualização (Central de Updates: tools/updates/) ──────────
    # Cada grupo tem os seus inputs e atualiza sozinho. Ver .agents/knowledge/updates.md.
    #   Sistema (drivers + ferramentas): nixpkgs, home-manager
    #   Programas: nixpkgs-apps, claude-desktop, bedrock-on-linux
    #   osu!: nixpkgs-osu
    #   Hyprland: nixpkgs-hyprland (rev fixa) + nixpkgs-mesa (rev fixa, acompanha a glibc dele)

    # Base do sistema: kernel, drivers (Mesa, firmware), PipeWire, systemd e ferramentas.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nixpkgs independente para os programas (modules/nixos/programs.nix).
    # Atualizar apenas os programas: nix flake update nixpkgs-apps
    nixpkgs-apps.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nixpkgs travado no commit exato que tem o Hyprland 0.55.
    # A rev fixa na URL faz com que `nix flake update` NUNCA mude este input.
    # Para atualizar o Hyprland no futuro, troque o hash aqui manualmente.
    nixpkgs-hyprland.url = "github:NixOS/nixpkgs/e73de5be04e0eff4190a1432b946d469c794e7b4";
    nixpkgs-hyprland.flake = false;

    # Mesa (userspace de vídeo) travada num nixpkgs com glibc <= a do Hyprland.
    # O Hyprland travado carrega a Mesa de /run/opengl-driver via dlopen; se ela
    # for compilada com uma glibc mais nova que a dele, o GBM não abre e o
    # compositor não sobe. Só troque esta rev junto com a do nixpkgs-hyprland.
    # Ver modules/nixos/amd-gpu.nix e .agents/knowledge/updates.md.
    nixpkgs-mesa.url = "github:NixOS/nixpkgs/34ab99075ac4f7e40cf037eef32cb1c360bb85e9";
    nixpkgs-mesa.flake = false;

    # nixpkgs independente para o osu-lazer.
    # Atualizar apenas o osu: nix flake update nixpkgs-osu
    nixpkgs-osu.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Minecraft Bedrock (Windows/GDK) via WineGDK — NÃO actualizar o hyprland.
    bedrock-on-linux = {
      url = "github:Wyze3306/BedrockOnLinux";
      inputs.nixpkgs.follows = "nixpkgs-apps";
    };

    # Claude Desktop (comunidade, reempacota o .deb oficial). Atualizar só ele: nix flake update claude-desktop
    claude-desktop.url = "github:aaddrick/claude-desktop-debian";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # A tag @inputs captura tudo o que foi definido acima e empacota numa variável
  outputs = { self, nixpkgs, nixpkgs-apps, nixpkgs-hyprland, nixpkgs-mesa, nixpkgs-osu, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      # Checkout deve viver em /etc/nixos para symlinks mkOutOfStoreSymlink apontarem para ficheiros editáveis.
      repoRoot = "/etc/nixos";
      # Hyprland vem SEMPRE daqui (commit fixo). Use pkgs-hyprland.hyprland nos módulos.
      pkgs-hyprland = import nixpkgs-hyprland { inherit system; config.allowUnfree = true; };
      # Mesa vem SEMPRE daqui enquanto o Hyprland estiver travado (ver input nixpkgs-mesa).
      pkgs-mesa = import nixpkgs-mesa { inherit system; config.allowUnfree = true; };
      pkgs-osu = import nixpkgs-osu { inherit system; config.allowUnfree = true; };
      # Programas vêm SEMPRE daqui. Sem overlays: os de nixpkgs.overlays são só do pkgs base.
      pkgs-apps = import nixpkgs-apps { inherit system; config.allowUnfree = true; };
    in
    {
      nixosConfigurations.alice-nixos = nixpkgs.lib.nixosSystem {
        # Passa as variáveis para o nível do sistema NixOS
        specialArgs = { inherit repoRoot pkgs-hyprland pkgs-mesa pkgs-osu pkgs-apps inputs; };

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
