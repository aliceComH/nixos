# ── Voice Normalizer: Virtual Sink com Compressor + Limiter (LADSPA) ─────────
#
# Cria uma filter-chain do PipeWire que aparece como um sink virtual chamado
# "Voice Normalizer". O Discord (ou qualquer app) pode ser apontado para esse
# sink via pavucontrol/wpctl. O áudio é processado em tempo real por:
#
#   SC4 Stereo Compressor  →  Fast Lookahead Limiter
#
# A saída (playback) segue automaticamente o dispositivo de áudio padrão do
# sistema, sem necessidade de scripts ou reconexão manual.
#
# Parâmetros do SC4 estão ajustados para voz/conversação:
#   - Threshold -18 dB: captura a maioria das vozes antes de ficarem altas
#   - Ratio 4:1: compressão moderada (não esmaga a dinâmica natural)
#   - Attack 15ms: rápido o suficiente para pegar picos de voz
#   - Release 300ms: suave, evita pumping audível
#   - Makeup gain +6 dB: compensa a redução de ganho, trazendo vozes baixas
#   - Knee 6 dB: transição suave entre não-comprimido e comprimido
#   - RMS/peak = 0.5: mix entre RMS e peak detection (bom para voz)
#
# O Limiter atua como safety net:
#   - Limit -3 dB: hard ceiling, ninguém ultrapassa isso
#   - Input gain 0 dB: sem ganho adicional antes do limiter
#   - Release 0.01s: release ultra-rápido para transparência
#
# NOTA: O campo `plugin` em nós LADSPA do PipeWire aceita apenas o nome base
# (sem path e sem .so). O PipeWire appenda .so automaticamente e procura no
# LADSPA_PATH, que o NixOS popula via `extraLadspaPackages`.

{ pkgs, ... }:

{
  services.pipewire = {

    # ── Registra o pacote SWH no LADSPA_PATH do PipeWire ───────────────────
    # O NixOS monta o diretório `pipewire-ladspa-plugins/lib/ladspa/` com
    # symlinks para os .so de cada pacote listado aqui. Sem isso, o PipeWire
    # não encontra os plugins e o módulo filter-chain falha ao carregar.
    extraLadspaPackages = [ pkgs.ladspaPlugins ];

    # ── Filter-Chain: Compressor + Limiter para normalização de voz ────────
    extraConfig.pipewire."50-voice-normalizer" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Voice Normalizer";
            "media.name"       = "Voice Normalizer";

            "filter.graph" = {
              nodes = [
                # ── Stage 1: SC4 Stereo Compressor ───────────────────────
                # Plugin stereo: Left input/Right input → Left output/Right output
                {
                  type   = "ladspa";
                  name   = "compressor";
                  plugin = "sc4_1882";
                  label  = "sc4";
                  control = {
                    # 0 = peak, 1 = RMS, 0.5 = mix (melhor para voz)
                    "RMS/peak"              = 0.5;
                    "Attack time (ms)"      = 15.0;
                    "Release time (ms)"     = 300.0;
                    "Threshold level (dB)"  = -18.0;
                    "Ratio (1:n)"           = 4.0;
                    "Knee radius (dB)"      = 6.0;
                    "Makeup gain (dB)"      = 6.0;
                  };
                }

                # ── Stage 2: Fast Lookahead Limiter ──────────────────────
                # Safety net: impede qualquer pico acima de -3 dB.
                # Plugin stereo: Input 1/Input 2 → Output 1/Output 2
                {
                  type   = "ladspa";
                  name   = "limiter";
                  plugin = "fast_lookahead_limiter_1913";
                  label  = "fastLookaheadLimiter";
                  control = {
                    "Input gain (dB)"    = 0.0;
                    "Limit (dB)"         = -3.0;
                    "Release time (s)"   = 0.01;
                  };
                }
              ];

              # ── Links internos do grafo ──────────────────────────────────
              # SC4 stereo out → Limiter stereo in
              links = [
                { output = "compressor:Left output";  input = "limiter:Input 1"; }
                { output = "compressor:Right output"; input = "limiter:Input 2"; }
              ];
            };

            # ── Capture: lado de entrada (Virtual Sink) ──────────────────
            # Apps como Discord enviam áudio para cá.
            "capture.props" = {
              "node.name"         = "voice_normalizer_sink";
              "media.class"       = "Audio/Sink";
              "audio.channels"    = 2;
              "audio.position"    = [ "FL" "FR" ];

              # Mantém a filter-chain processando mesmo sem clientes
              # conectados, evitando pop/crackle ao conectar o primeiro stream.
              "node.always-process" = true;
            };

            # ── Playback: lado de saída (segue o default sink) ───────────
            "playback.props" = {
              "node.name"            = "voice_normalizer_output";
              "audio.channels"       = 2;
              "audio.position"       = [ "FL" "FR" ];

              # ╔══════════════════════════════════════════════════════════╗
              # ║  FLAGS CRÍTICAS PARA "FOLLOW DEFAULT SINK"              ║
              # ╠══════════════════════════════════════════════════════════╣
              # ║                                                          ║
              # ║  node.passive = true                                     ║
              # ║    → Informa ao WirePlumber que este nó NÃO deve manter  ║
              # ║      o sink de destino "ocupado". Sem isso, o WP trata   ║
              # ║      a filter-chain como um cliente ativo e pode impedir ║
              # ║      o suspend/idle do dispositivo de áudio.             ║
              # ║                                                          ║
              # ║  node.dont-reconnect = false                             ║
              # ║    → Permite que o WirePlumber MOVA este stream para     ║
              # ║      outro dispositivo quando o default sink mudar.      ║
              # ║      Se fosse true, o stream ficaria preso ao device     ║
              # ║      original e não seguiria mudanças de default.        ║
              # ║                                                          ║
              # ║  stream.dont-remix = true                                ║
              # ║    → Preserva o layout de canais (FL+FR) do stream sem   ║
              # ║      remixar para o formato do sink de destino. Evita    ║
              # ║      artefatos de downmix/upmix indesejados.            ║
              # ║                                                          ║
              # ║  AUSÊNCIA de target.object / node.target:                ║
              # ║    → Ao NÃO especificar um alvo fixo, o WirePlumber usa  ║
              # ║      sua política padrão (find-default-target.lua) para  ║
              # ║      rotear este stream para @DEFAULT_AUDIO_SINK@.       ║
              # ║      Quando você muda o default (via wpctl, pavucontrol, ║
              # ║      ou seletor do Hyprland), o WP automaticamente       ║
              # ║      desconecta do device antigo e reconecta ao novo.    ║
              # ║                                                          ║
              # ╚══════════════════════════════════════════════════════════╝

              "node.passive"         = true;
              "node.dont-reconnect"  = false;
              "stream.dont-remix"    = true;
            };
          };
        }
      ];
    };
  };
}
