# Grupos de atualização — alimenta a Central de Updates (tools/updates/updates.py).
#
# Cada módulo declara em `local.updateGroups.<grupo>` os pacotes que pertencem ao
# grupo. Esta opção é só informativa: NÃO instala nada (quem instala é o próprio
# módulo, via environment.systemPackages / programs.<x>). Daqui sai o
# /etc/update-groups.json com nome e versão de cada pacote do sistema ativo.
#
# Grupo -> inputs do flake (fonte da verdade: tools/updates/update-group.sh):
#   hyprland    -> nixpkgs-hyprland (rev fixa em flake.nix)
#   osu         -> nixpkgs-osu
#   programas   -> nixpkgs-apps, antigravity-nix, claude-desktop, bedrock-on-linux
#   drivers + ferramentas ("Sistema") -> nixpkgs, home-manager
#
# Drivers e ferramentas atualizam juntos porque kernel, Mesa, systemd, PipeWire e
# o userland base saem de uma única avaliação do NixOS (o `pkgs` do sistema).
{ config, lib, pkgs, ... }:

let
  describe = p: {
    name = lib.getName p;
    version = lib.getVersion p;
  };
in
{
  options.local.updateGroups = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.package);
    default = { };
    description = "Pacotes de cada grupo de atualização (informativo; não instala).";
  };

  config = {
    # Drivers: o que este host realmente usa do pkgs base.
    local.updateGroups.drivers = [
      config.boot.kernelPackages.kernel
      pkgs.linux-firmware
      pkgs.mesa
      config.services.pipewire.package
      config.services.pipewire.wireplumber.package
      pkgs.lact
      pkgs.opentabletdriver
      pkgs.libratbag
      pkgs.piper
      pkgs.solaar
    ];

    environment.etc."update-groups.json".text = builtins.toJSON (
      lib.mapAttrs (_: ps: map describe ps) config.local.updateGroups
    );
  };
}
