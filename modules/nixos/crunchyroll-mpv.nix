# Módulo NixOS: media-stream
# Cria o comando "media-stream" que orquestra o pipeline:
#   1. Garante que a Crunchyroll-Sink existe (reutiliza se já estiver ativa)
#   2. Levanta o OBS em background (minimizado na tray)
#   3. Aciona a gravação (stream UDP) via obs-cmd
#   4. Abre o MPV para ler o stream com interpolação flowFPS
#   5. Ao fechar o MPV, para a gravação e mata o OBS.
{ pkgs, ... }:

let
  pactl = "${pkgs.pulseaudio}/bin/pactl";

  media-stream-script = pkgs.writeShellScriptBin "media-stream" ''
    set -euo pipefail

    SINK_NAME="Crunchyroll-Sink"
    CREATED_SINK=""
    OBS_PID=""
    UDP_ADDR="udp://127.0.0.1:1234"

    cleanup() {
      echo "▶ Limpando..."
      obs-cmd recording stop 2>/dev/null || true

      if [[ -n "''${OBS_PID:-}" ]]; then
        kill "$OBS_PID" 2>/dev/null || true
        wait "$OBS_PID" 2>/dev/null || true
      fi

      if [[ -n "''${CREATED_SINK:-}" ]]; then
        ${pactl} unload-module "$CREATED_SINK" 2>/dev/null || true
      fi

      echo "✔ Limpeza concluída."
    }
    trap cleanup EXIT

    # ── 1. Garante que a sink existe ─────────────────────────────────────
    if ${pactl} list sinks short 2>/dev/null | grep -q "$SINK_NAME"; then
      echo "✔ Sink $SINK_NAME já existe, reutilizando."
    else
      echo "▶ Criando sink $SINK_NAME..."
      CREATED_SINK=$(${pactl} load-module module-null-sink \
        sink_name="$SINK_NAME" \
        sink_properties=device.description="$SINK_NAME")
      echo "✔ Sink criada (module ID: $CREATED_SINK)"
    fi

    # ── 2. Levanta o OBS minimizado ──────────────────────────────────────
    echo "▶ Iniciando OBS Studio (minimizado)..."
    obs --minimize-to-tray &
    OBS_PID=$!

    # Espera o WebSocket do OBS ficar pronto (porta 4455).
    # obs-cmd info crashava, então usamos polling direto na porta.
    echo "▶ Aguardando WebSocket do OBS (porta 4455)..."
    for i in $(seq 1 30); do
      if ${pkgs.socat}/bin/socat -T1 /dev/null TCP:127.0.0.1:4455 2>/dev/null; then
        echo "✔ WebSocket pronto!"
        break
      fi
      sleep 1
    done

    # ── 3. Inicia a gravação/stream via obs-cmd ──────────────────────────
    echo "▶ Iniciando gravação (stream UDP)..."
    obs-cmd recording start
    sleep 2

    # ── 4. Lança o MPV ───────────────────────────────────────────────────
    echo "▶ Iniciando MPV (stream: $UDP_ADDR)..."
    mpv "$UDP_ADDR"

    echo "▶ MPV encerrado."
  '';
in
{
  environment.systemPackages = [
    media-stream-script
  ];
}
