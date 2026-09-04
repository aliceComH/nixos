{
  lib,
  pkgs,
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

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };

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
