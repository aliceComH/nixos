{ pkgs, ... }:

{
  # Autologin na consola (substitui o override manual de getty@tty1, que quebrava o ExecStart
  # oficial do NixOS: faltava --login-program e o wrapper correcto do módulo getty.nix).
  services.getty.autologinUser = "alice";

  fonts.packages = with pkgs; [
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    font-awesome
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap.enable = true;

  networking.networkmanager.enable = true;

  # Disques (gnome-disk-utility), Thunar-volman e montagens automáticas via D-Bus
  # precisam do udisks2 activo; sem o serviço a lista de discos fica vazia.
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Partições exFAT (p.ex. SSDs externos formatados no Windows).
  boot.supportedFilesystems = [ "exfat" ];

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

  programs.nix-ld = {
    enable = true;
    # libgbm.so.1 é necessário para o gatherer do Mission Center (flatpak)
    # correr fora do sandbox no host NixOS.
    libraries = with pkgs; [ libgbm ];
  };

  security.sudo.wheelNeedsPassword = false;
}
