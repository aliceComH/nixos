{ pkgs, ... }:

{
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
}
