# Piper + libratbag: remapeamento de botões do Logitech G502 Hero.
# O serviço ratbagd expõe o hardware via D-Bus; piper é a GUI GTK.
#
# O Piper 0.8 nomeia slots como "Profile {index}" (base 0). O perfil de uso
# diário é o índice 1. O G502 guarda 5 slots onboard; no replug o firmware
# pode ativar outro. Este oneshot só força o índice 1 — não desativa os
# restantes, para não apagar binds/DPI dos outros perfis.
{ pkgs, ... }:
let
  forceProfile = pkgs.writeShellApplication {
    name = "g502-force-profile";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.libratbag
    ];
    text = ''
      find_device() {
        ratbagctl list 2>/dev/null | grep -F 'G502' | head -n1 | cut -d: -f1
      }

      device=""
      i=0
      while [ "$i" -lt 40 ]; do
        device="$(find_device || true)"
        if [ -n "$device" ]; then
          break
        fi
        i=$((i + 1))
        sleep 0.25
      done

      if [ -z "$device" ]; then
        echo "g502-force-profile: G502 HERO ainda não visível no ratbagd" >&2
        exit 0
      fi

      ok=0
      i=0
      while [ "$i" -lt 20 ]; do
        if ratbagctl "$device" profile 1 enable \
          && ratbagctl "$device" profile active set 1; then
          ok=1
          break
        fi
        i=$((i + 1))
        sleep 0.25
      done

      if [ "$ok" -ne 1 ]; then
        echo "g502-force-profile: falhou ao ativar o perfil 1 em $device" >&2
        exit 1
      fi
    '';
  };
in
{
  services.ratbagd.enable = true;

  environment.systemPackages = [ pkgs.piper ];

  systemd.services.g502-force-profile = {
    description = "Força o Logitech G502 HERO para o perfil 1 (Piper Profile 1)";
    after = [
      "dbus.service"
      "ratbagd.service"
    ];
    wants = [ "ratbagd.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${forceProfile}/bin/g502-force-profile";
    };
  };

  # Dispara o oneshot em cada plug USB (id 046d:c08b = G502 HERO).
  # DEVTYPE=usb_device evita um start por cada interface HID.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="046d", ATTR{idProduct}=="c08b", TAG+="systemd", ENV{SYSTEMD_WANTS}="g502-force-profile.service"
  '';
}
