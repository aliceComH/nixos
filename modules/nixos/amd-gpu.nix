{
  lib,
  pkgs,
  pkgs-hyprland,
  pkgs-mesa,
  config,
  ...
}:

{
  options.local.amdgpuHdmiFrl.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Liga HDMI 2.1 Fixed Rate Link (FRL) no amdgpu. No Linux 7.2 o código
      já está no driver, mas desligado por omissão (bit DC_FRL_MASK = 0x400
      de dcfeaturemask) até o VRR HDMI 2.1 ficar maduro (~kernel 7.4).

      Sem isto, o kernel descarta timings acima do teto TMDS (~18 Gb/s),
      o que neste monitor esconde o DisplayID 3840x2160@143.86 Hz e deixa
      só 4K@120. Com FRL (até 48 Gb/s) esse modo passa a ser anunciado.

      Limitação actual: FRL e VRR HDMI não convivem neste kernel — o
      monitor HDMI-A-1 já está com vrr=0 no Hyprland. DisplayPort não é
      afectado. Rollback no menu de boot: specialisation `no-hdmi-frl`.
    '';
  };

  config = {
    services.xserver.videoDrivers = [ "amdgpu" ];

    # A Mesa NÃO vem do `pkgs` do sistema: o Hyprland (nixpkgs travado, glibc
    # antiga) faz dlopen de /run/opengl-driver/lib/gbm/dri_gbm.so. Uma Mesa
    # compilada com glibc mais nova falha com "GLIBC_2.xx not found", o
    # aquamarine loga "Couldn't open a GBM device" e o Hyprland aborta em
    # CBackend::create(). Apps mais novos carregam uma Mesa mais antiga sem
    # problema (glibc é compatível para trás), então trava-se pelo mais velho.
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      package = pkgs-mesa.mesa;
      package32 = pkgs-mesa.pkgsi686Linux.mesa;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };

    assertions = [
      {
        assertion = lib.versionAtLeast pkgs-hyprland.glibc.version pkgs-mesa.glibc.version;
        message = ''
          A Mesa (nixpkgs-mesa, glibc ${pkgs-mesa.glibc.version}) foi compilada com uma
          glibc mais nova que a do Hyprland (nixpkgs-hyprland, glibc
          ${pkgs-hyprland.glibc.version}). O Hyprland não conseguiria carregar o driver
          e não subiria. Use em nixpkgs-mesa uma rev com glibc <= a do Hyprland.
        '';
      }
    ];

    boot.extraModprobeConfig = ''
      options amdgpu ppfeaturemask=0xFFF7FFFF
    '';

    # Nome real do parâmetro no 7.2.2: dcfeaturemask (não dc_feature_mask).
    boot.kernelParams = lib.mkIf config.local.amdgpuHdmiFrl.enable [
      "amdgpu.dcfeaturemask=0x400"
    ];

    specialisation.no-hdmi-frl.configuration = {
      local.amdgpuHdmiFrl.enable = lib.mkForce false;
    };
  };
}
