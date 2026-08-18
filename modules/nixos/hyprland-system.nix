{ pkgs, pkgs-hyprland, ... }:

{

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs-hyprland.hyprland;
    portalPackage = pkgs-hyprland.xdg-desktop-portal-hyprland;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "0";
    BROWSER = "firefox";
  };

  # Mantemos os portais explícitos para evitar regressões de screen share.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  xdg.portal.config = {
    common = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
    };
    hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
    };
  };

  # PATH mínimo do portal não inclui /etc/profiles/.../bin; firefox.desktop
  # relativo falha e o fallback do Electron é o Chrome (Exec absoluto).
  systemd.user.services.xdg-desktop-portal.environment.PATH =
    "/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin:/run/wrappers/bin";

  # ── Fix: screen share do Vesktop/Discord "morrendo" até reiniciar a máquina ──
  # xdg-desktop-portal e xdg-desktop-portal-hyprland ficam rodando por dias
  # (não são reiniciados no dia a dia), mas seguram uma conexão de socket
  # com o pipewire.service. Toda vez que o PipeWire reinicia — nixos-rebuild
  # switch, `systemctl --user restart pipewire`, crash — essa conexão morre
  # e NÃO se reconecta sozinha (log: "Caught PipeWire error: connection
  # error"). Resultado: screen share falha silenciosamente até um reboot
  # completo, que por acaso reinicia tudo junto.
  #
  # PartOf propaga stop/restart do alvo para a unidade que o declara (mas
  # não o contrário): reiniciar pipewire.service ou wireplumber.service
  # agora força o portal a reiniciar junto e reconectar no socket novo.
  systemd.user.services."xdg-desktop-portal".unitConfig.PartOf = [
    "pipewire.service"
    "wireplumber.service"
  ];
  systemd.user.services."xdg-desktop-portal-hyprland".unitConfig.PartOf = [
    "pipewire.service"
    "wireplumber.service"
  ];
}
