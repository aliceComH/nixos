{ pkgs, ... }:

let
  mirrorScript = pkgs.writeShellScriptBin "mirror-audio" ''
    set -euo pipefail

    internal_service_name="hyperx-internal-mirror.service"
    cloud3_service_name="hyperx-cloud3-mirror.service"

    rg_bin="${pkgs.ripgrep}/bin/rg"
    sed_bin="${pkgs.gnused}/bin/sed"
    head_bin="${pkgs.coreutils}/bin/head"
    mkdir_bin="${pkgs.coreutils}/bin/mkdir"
    wpctl_bin="${pkgs.wireplumber}/bin/wpctl"
    pwlink_bin="${pkgs.pipewire}/bin/pw-link"
    pwloop_bin="${pkgs.pipewire}/bin/pw-loopback"
    state_dir="''${XDG_RUNTIME_DIR:-/tmp}"
    internal_toggle_file="$state_dir/hyperx-internal-mirror.enabled"

    is_internal_toggle_enabled() {
      [ -f "$internal_toggle_file" ] && [ "$(<"$internal_toggle_file")" = "1" ]
    }

    set_internal_toggle_enabled() {
      local value="$1"
      "$mkdir_bin" -p "$state_dir"
      printf '%s\n' "$value" > "$internal_toggle_file"
    }

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

    resolve_internal_sink() {
      local sink
      # Busca pelo sink IEC958 (Estéreo digital) do áudio interno
      sink="$($pwlink_bin -i | $rg_bin '^alsa_output\..*iec958.*:playback_FL$' | $head_bin -n1 | $sed_bin 's/:playback_FL$//' || true)"
      if [ -z "$sink" ]; then
        # Fallback genérico para áudio interno PCI (ignora saídas de vídeo hdmi e fones usb)
        sink="$($pwlink_bin -i | $rg_bin '^alsa_output\.pci-.*:playback_FL$' | $rg_bin -v -i 'hdmi|usb' | $head_bin -n1 | $sed_bin 's/:playback_FL$//' || true)"
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

    run_internal_loopback() {
      local hyperx_sink internal_sink

      if ! is_default_hyperx_7_1; then
        echo "mirror-audio: loopback Áudio interno só é permitido com HyperX 7.1 como sink default." >&2
        exit 1
      fi

      hyperx_sink="$(resolve_hyperx_sink)"
      internal_sink="$(resolve_internal_sink)"

      if [ -z "$hyperx_sink" ]; then
        echo "mirror-audio: não encontrei monitor do sink HyperX." >&2
        exit 1
      fi

      if [ -z "$internal_sink" ]; then
        echo "mirror-audio: não encontrei sink Áudio interno para espelho." >&2
        exit 1
      fi

      echo "mirror-audio: capture=$hyperx_sink.monitor -> playback=$internal_sink"
      exec "$pwloop_bin" -n hyperx-internal-mirror -C "$hyperx_sink" -i stream.capture.sink=true -P "$internal_sink" -c 2 -m '[ FL FR ]' --latency 64/48000 --quantum 64
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
      exec "$pwloop_bin" -n hyperx-cloud3-mirror -C "$hyperx_sink" -i stream.capture.sink=true -P "$cloud3_sink" -c 2 -m '[ FL FR ]' --latency 64/48000 --quantum 64
    }

    reconcile_loopbacks() {
      local hyperx_sink internal_sink cloud3_sink

      if ! is_default_hyperx_7_1; then
        # Ao sair do default 7.1, reseta o toggle do Áudio interno para estado padrão OFF.
        set_internal_toggle_enabled 0
        systemctl --user stop "$internal_service_name" "$cloud3_service_name"
        echo "mirror-audio: default!=HyperX 7.1 -> Áudio interno OFF, Cloud3 OFF"
        return 0
      fi

      hyperx_sink="$(resolve_hyperx_sink)"
      internal_sink="$(resolve_internal_sink)"
      cloud3_sink="$(resolve_cloud3_sink)"

      if [ -z "$hyperx_sink" ]; then
        systemctl --user stop "$internal_service_name" "$cloud3_service_name"
        echo "mirror-audio: monitor do HyperX indisponível -> Áudio interno OFF, Cloud3 OFF"
        return 0
      fi

      if ! is_internal_toggle_enabled; then
        systemctl --user stop "$internal_service_name"
        if [ -n "$cloud3_sink" ]; then
          systemctl --user start "$cloud3_service_name"
          echo "mirror-audio: toggle Áudio interno está OFF -> Áudio interno OFF, Cloud3 ON"
        else
          systemctl --user stop "$cloud3_service_name"
          echo "mirror-audio: toggle Áudio interno está OFF e Cloud3 desconectado -> Áudio interno OFF, Cloud3 OFF"
        fi
        return 0
      fi

      if [ -n "$internal_sink" ]; then
        systemctl --user start "$internal_service_name"
      else
        systemctl --user stop "$internal_service_name"
      fi

      # Cloud3 é independente do toggle/estado do Áudio interno:
      # sempre ON quando default=HyperX 7.1 e Cloud3 está conectado.
      if [ -n "$cloud3_sink" ]; then
        systemctl --user start "$cloud3_service_name"
        if [ -n "$internal_sink" ]; then
          echo "mirror-audio: default=HyperX 7.1 -> Cloud3 ON, Áudio interno ON (toggle)"
        else
          echo "mirror-audio: default=HyperX 7.1 -> Cloud3 ON, Áudio interno OFF (desconectado)"
        fi
      else
        systemctl --user stop "$cloud3_service_name"
        if [ -z "$cloud3_sink" ]; then
          echo "mirror-audio: Cloud3 desconectado -> Cloud3 OFF"
        fi
      fi
    }

    case "''${1:-}" in
      run-internal)
        run_internal_loopback
        ;;
      run-cloud3)
        run_cloud3_loopback
        ;;
      start)
        if is_default_hyperx_7_1; then
          reconcile_loopbacks
        else
          systemctl --user stop "$internal_service_name"
          systemctl --user stop "$cloud3_service_name"
          echo "mirror-audio: aguardando default sink HyperX 7.1."
        fi
        ;;
      stop)
        set_internal_toggle_enabled 0
        systemctl --user stop "$internal_service_name"
        systemctl --user stop "$cloud3_service_name"
        ;;
      restart)
        if is_default_hyperx_7_1; then
          reconcile_loopbacks
        else
          systemctl --user stop "$internal_service_name"
          systemctl --user stop "$cloud3_service_name"
          echo "mirror-audio: aguardando default sink HyperX 7.1."
        fi
        ;;
      toggle)
        if is_internal_toggle_enabled; then
          set_internal_toggle_enabled 0
          systemctl --user stop "$internal_service_name"
          echo "mirror-audio: Áudio interno OFF (toggle)"
        else
          set_internal_toggle_enabled 1
          reconcile_loopbacks
          if systemctl --user --quiet is-active "$internal_service_name"; then
            echo "mirror-audio: Áudio interno ON (toggle)"
          else
            echo "mirror-audio: Áudio interno ON solicitado (aguardando dispositivos compatíveis)"
          fi
        fi
        ;;
      reconcile)
        reconcile_loopbacks
        ;;
      status)
        systemctl --user status "$internal_service_name" --no-pager
        systemctl --user status "$cloud3_service_name" --no-pager
        ;;
      *)
        echo "uso: mirror-audio {run-internal|run-cloud3|start|stop|restart|toggle|reconcile|status}" >&2
        exit 2
        ;;
    esac
  '';
in
{
  home.packages = [ mirrorScript ];

  systemd.user.services.hyperx-internal-mirror = {
    Unit = {
      Description = "Mirror HyperX sink monitor to Internal Audio sink";
      After = [ "pipewire.service" "wireplumber.service" ];
      Wants = [ "pipewire.service" "wireplumber.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${mirrorScript}/bin/mirror-audio run-internal";
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
