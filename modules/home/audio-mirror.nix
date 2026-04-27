{ pkgs, ... }:

let
  mirrorScript = pkgs.writeShellScriptBin "mirror-audio" ''
    set -euo pipefail

    hdmi_service_name="hyperx-hdmi-mirror.service"
    cloud3_service_name="hyperx-cloud3-mirror.service"

    rg_bin="${pkgs.ripgrep}/bin/rg"
    sed_bin="${pkgs.gnused}/bin/sed"
    head_bin="${pkgs.coreutils}/bin/head"
    wpctl_bin="${pkgs.wireplumber}/bin/wpctl"
    pwlink_bin="${pkgs.pipewire}/bin/pw-link"
    pwloop_bin="${pkgs.pipewire}/bin/pw-loopback"

    is_default_hyperx_7_1() {
      "$wpctl_bin" inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null \
        | "$rg_bin" -qi 'HyperX 7\.1 Audio|Kingston_HyperX_Virtual_Surround_Sound'
    }

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

    resolve_cloud3_sink() {
      local sink
      sink="$($pwlink_bin -i | $rg_bin '^alsa_output\.usb-.*HyperX_Cloud_III_Wireless.*:playback_FL$' | $head_bin -n1 | $sed_bin 's/:playback_FL$//' || true)"
      if [ -z "$sink" ]; then
        sink="$($pwlink_bin -i | $rg_bin '^alsa_output\..*HyperX.*Cloud.*Wireless.*:playback_FL$' | $head_bin -n1 | $sed_bin 's/:playback_FL$//' || true)"
      fi
      echo "$sink"
    }

    run_hdmi_loopback() {
      local hyperx_sink hdmi_sink

      if ! is_default_hyperx_7_1; then
        echo "mirror-audio: loopback HDMI só é permitido com HyperX 7.1 como sink default." >&2
        exit 1
      fi

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

    run_cloud3_loopback() {
      local hyperx_sink cloud3_sink

      if ! is_default_hyperx_7_1; then
        echo "mirror-audio: default sink não é HyperX 7.1, não vou manter loopback Cloud3." >&2
        exit 1
      fi

      hyperx_sink="$(resolve_hyperx_sink)"
      cloud3_sink="$(resolve_cloud3_sink)"

      if [ -z "$hyperx_sink" ]; then
        echo "mirror-audio: não encontrei monitor do sink HyperX." >&2
        exit 1
      fi

      if [ -z "$cloud3_sink" ]; then
        echo "mirror-audio: não encontrei sink HyperX Cloud 3 Wireless para espelho." >&2
        exit 1
      fi

      echo "mirror-audio: capture=$hyperx_sink.monitor -> playback=$cloud3_sink"
      exec "$pwloop_bin" -n hyperx-cloud3-mirror -C "$hyperx_sink" -i stream.capture.sink=true -P "$cloud3_sink" -c 2 -m '[ FL FR ]' --latency 100
    }

    reconcile_loopbacks() {
      if is_default_hyperx_7_1; then
        systemctl --user start "$cloud3_service_name"
        echo "mirror-audio: default=HyperX 7.1 -> Cloud3 ON"
      else
        systemctl --user stop "$hdmi_service_name" "$cloud3_service_name"
        echo "mirror-audio: default!=HyperX 7.1 -> HDMI OFF, Cloud3 OFF"
      fi
    }

    case "''${1:-}" in
      run)
        run_hdmi_loopback
        ;;
      run-cloud3)
        run_cloud3_loopback
        ;;
      start)
        if is_default_hyperx_7_1; then
          systemctl --user start "$hdmi_service_name"
        else
          systemctl --user stop "$hdmi_service_name"
          echo "mirror-audio: HDMI mirror bloqueado porque default sink não é HyperX 7.1."
        fi
        ;;
      stop)
        systemctl --user stop "$hdmi_service_name"
        ;;
      restart)
        if is_default_hyperx_7_1; then
          systemctl --user restart "$hdmi_service_name"
        else
          systemctl --user stop "$hdmi_service_name"
          echo "mirror-audio: HDMI mirror bloqueado porque default sink não é HyperX 7.1."
        fi
        ;;
      toggle)
        if ! is_default_hyperx_7_1; then
          systemctl --user stop "$hdmi_service_name"
          echo "mirror-audio: HDMI OFF (default sink não é HyperX 7.1)."
        elif systemctl --user --quiet is-active "$hdmi_service_name"; then
          systemctl --user stop "$hdmi_service_name"
          echo "mirror-audio: OFF"
        else
          systemctl --user start "$hdmi_service_name"
          echo "mirror-audio: ON"
        fi
        ;;
      reconcile)
        reconcile_loopbacks
        ;;
      status)
        systemctl --user status "$hdmi_service_name" --no-pager
        systemctl --user status "$cloud3_service_name" --no-pager
        ;;
      *)
        echo "uso: mirror-audio {run|run-cloud3|start|stop|restart|toggle|reconcile|status}" >&2
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

  systemd.user.services.hyperx-cloud3-mirror = {
    Unit = {
      Description = "Mirror HyperX sink monitor to HyperX Cloud 3 Wireless sink";
      After = [ "pipewire.service" "wireplumber.service" ];
      Wants = [ "pipewire.service" "wireplumber.service" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${mirrorScript}/bin/mirror-audio run-cloud3";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  systemd.user.services.hyperx-loopback-reconcile = {
    Unit = {
      Description = "Reconcile HyperX loopbacks against current default sink";
      After = [ "pipewire.service" "wireplumber.service" ];
      Wants = [ "pipewire.service" "wireplumber.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${mirrorScript}/bin/mirror-audio reconcile";
    };

    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.timers.hyperx-loopback-reconcile = {
    Unit = {
      Description = "Periodic reconcile of HyperX loopbacks";
    };

    Timer = {
      OnBootSec = "10s";
      OnUnitActiveSec = "5s";
      Unit = "hyperx-loopback-reconcile.service";
    };

    Install.WantedBy = [ "timers.target" ];
  };
}
