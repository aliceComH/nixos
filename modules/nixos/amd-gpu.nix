{ pkgs, ... }:

{
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.extraModprobeConfig = ''
    options amdgpu ppfeaturemask=0xFFF7FFFF
  '';
}
