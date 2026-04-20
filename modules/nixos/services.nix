{ pkgs, lib, ... }:

{
  # Equivalente ao drop-in getty@tty1 (autologin alice); substitui system/etc/ no repo.
  systemd.services."getty@tty1".serviceConfig.ExecStart = lib.mkForce [
    ""
    "-${pkgs.util-linux}/bin/agetty --autologin alice --noclear %I $TERM"
  ];

  fonts.packages = with pkgs; [
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    jetbrains-mono
    font-awesome
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap.enable = true;

  networking.networkmanager.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };
  services.pipewire.wireplumber.enable = true;

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  hardware.opentabletdriver.enable = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  programs.steam.enable = true;

  services.tuned.enable = true;

  # Expoe/ativa unidade lactd a partir do pacote do LACT.
  systemd.packages = [ pkgs.lact ];
  systemd.services.lactd = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  programs.dconf.enable = true;

  programs.zsh.enable = true;
}
