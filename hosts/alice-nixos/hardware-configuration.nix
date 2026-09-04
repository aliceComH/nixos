# Gerado como *template*: substitua os UUIDs após particionar e rodar
# `nixos-generate-config --root /mnt` na máquina alvo.
#
# Layout alvo: UEFI + /boot (vfat) + / (F2FS), zramSwap em configuration (services.nix).
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Substitua pelo UUID real da partição F2FS (blkid). UUID abaixo é só placeholder válido.
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f10bb535-6808-4e2b-bfe9-3e22bb929f2e";
    fsType = "f2fs";
    options = [
      "defaults"
      "noatime"
      "compress_algorithm=zstd"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F48A-E147";
    fsType = "vfat";
    options = [
      "defaults"
      "noatime"
      "umask=0077"
      "shortname=winnt"
    ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
