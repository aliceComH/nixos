{ pkgs, ... }:

let
  mirrorScript = pkgs.writeShellScriptBin "mirror-audio" ''
    set -euo pipefail

    service_name="hyperx-hdmi-mirror.service"

    rg_bin="${pkgs.ripgrep}/bin/rg"
    sed_bin="${pkgs.gnused}/bin/sed"
    head_bin="${pkgs.coreutils}/bin/head"
    pwlink_bin="${pkgs.pipewire}/bin/pw-link"
    pwloop_bin="${pkgs.pipewire}/bin/pw-loopback"

    resolve_hyperx_sink() {
      local sink
      sink="$($pwlink_bin -o | $rg_bin '^alsa_output\.usb-Kingston_HyperX_Virtual_Surround_Sound_.*:monitor_FL$' | $head_bin -n1 | $sed_bin 's/:monitor_FL$//' || true)"
      if [ -z "$sink" ]; then
        sink="$($pwlink_bin -o | $rg_bin '^alsa_output\.usb-.*HyperX.*:monitor_FL$' | $head_bin -n1 | $sed_bin 's/:monitor_FL$//' || true)"
      fi
      echo "$sink"
    }

    resolve_hdmi_sink() {
      local sink
      sink="$($pwlink_bin -i | $rg_bin '^alsa_output\.pci-0000_03_00\.1\.hdmi-.*:playback_FL$' | $head_bin -n1 | $sed_bin 's/:playback_FL$//' || true)"
      if [ -z "$sink" ]; then
        sink="$($pwlink_bin -i | $rg_bin '^alsa_output\..*hdmi.*:playback_FL$' | $head_bin -n1 | $sed_bin 's/:playback_FL$//' || true)"
      fi
      echo "$sink"
    }

    run_loopback() {
      local hyperx_sink hdmi_sink

      hyperx_sink="$(resolve_hyperx_sink)"
      hdmi_sink="$(resolve_hdmi_sink)"

      if [ -z "$hyperx_sink" ]; then
        echo "mirror-audio: não encontrei monitor do sink HyperX." >&2
        exit 1
      fi

      if [ -z "$hdmi_sink" ]; then
        echo "mirror-audio: não encontrei sink HDMI para espelho." >&2
        exit 1
      fi

      echo "mirror-audio: capture=$hyperx_sink.monitor -> playback=$hdmi_sink"
      exec "$pwloop_bin" -n hyperx-hdmi-mirror -C "$hyperx_sink" -i stream.capture.sink=true -P "$hdmi_sink" -c 2 -m '[ FL FR ]' --latency 100
    }

    case "''${1:-}" in
      run)
        run_loopback
        ;;
      start)
        systemctl --user start "$service_name"
        ;;
      stop)
        systemctl --user stop "$service_name"
        ;;
      restart)
        systemctl --user restart "$service_name"
        ;;
      toggle)
        if systemctl --user --quiet is-active "$service_name"; then
          systemctl --user stop "$service_name"
          echo "mirror-audio: OFF"
        else
          systemctl --user start "$service_name"
          echo "mirror-audio: ON"
        fi
        ;;
      status)
        systemctl --user status "$service_name" --no-pager
        ;;
      *)
        echo "uso: mirror-audio {run|start|stop|restart|toggle|status}" >&2
        exit 2
        ;;
    esac
  '';
in
{
  home.packages = [ mirrorScript ];

  systemd.user.services.hyperx-hdmi-mirror = {
    Unit = {
      Description = "Mirror HyperX sink monitor to HDMI sink";
      After = [ "pipewire.service" "wireplumber.service" ];
      Wants = [ "pipewire.service" "wireplumber.service" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${mirrorScript}/bin/mirror-audio run";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
