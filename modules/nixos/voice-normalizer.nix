# ── Voice Normalizer: Virtual Sink com Auto-Level + Compressor + Limiter ─────
#
# Cria uma filter-chain do PipeWire que aparece como um sink virtual chamado
# "Voice Normalizer". O Discord (ou qualquer app) pode ser apontado para esse
# sink via pavucontrol/wpctl. O áudio é processado em tempo real por:
#
#   Dyson Compressor (L/R)  →  SC4 Stereo Compressor  →  Fast Lookahead Limiter
#
# A saída (playback) segue automaticamente o dispositivo de áudio padrão do
# sistema, sem necessidade de scripts ou reconexão manual.
#
# Stage 1 — Dyson Compressor (auto-leveler, por canal):
#   O Dyson mede o nível do sinal e ajusta o ganho automaticamente: vozes
#   baixas/sussurros sobem, vozes altas descem. É o único plugin aqui que
#   faz "upward compression" de verdade — o SC4 sozinho não levanta o que
#   está abaixo do threshold, só aplica makeup gain uniforme.
#   - Peak limit -8 dB: teto de saída mais baixo e confortável
#   - Compression ratio 0.99 + fast ratio 1.0: nivelamento máximo
#   - Release 0.6s: recuperação suave, sem pumping entre falas
#
# Stage 2 — SC4 Stereo Compressor (achata o que sobrou):
#   - Threshold -30 dB: piso mínimo do plugin — tudo entra na compressão
#   - Ratio 20:1: máximo do plugin — dinâmica residual praticamente zerada
#   - Makeup gain +10 dB: compensa perda pós-Dyson e empurra tudo pro teto
#   - Attack 5ms / Release 250ms: evita oscilação de ganho audível
#   - Knee 1 dB: transição dura — sem "zona mole" de volume
#
# Stage 3 — Fast Lookahead Limiter (hard ceiling):
#   - Limit -8 dB: teto final alinhado ao Dyson, nada passa disso
#   - Input gain 0 dB: sem empurrar extra contra o teto
#   - Release 0.2s: evita zipper noise (0.01s craqueava com ganho oscilando)
#
# Quantum/latency: 64/48000 — alinhado ao graph global (ver pipewire-quantum.md).
#   Não aumentar; osu! e o resto do sistema dependem desse valor fixo.
#
# NOTA: O campo `plugin` em nós LADSPA do PipeWire aceita apenas o nome base
# (sem path e sem .so). O PipeWire appenda .so automaticamente e procura no
# LADSPA_PATH, que o NixOS popula via `extraLadspaPackages`.

{ pkgs, ... }:

{
  services.pipewire = {

    extraLadspaPackages = [ pkgs.ladspaPlugins ];

    extraConfig.pipewire."50-voice-normalizer" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Voice Normalizer";
            "media.name"       = "Voice Normalizer";

            "filter.graph" = {
              nodes = [
                # ── Stage 1a: Dyson Compressor — canal esquerdo ──────────
                # Auto-leveler: sobe sussurros, abaixa gritos, por canal.
                {
                  type   = "ladspa";
                  name   = "leveler_l";
                  plugin = "dyson_compress_1403";
                  label  = "dysonCompress";
                  control = {
                    # -8 dB: teto de saída — tudo converge pra esse nível.
                    "Peak limit (dB)"          = -8.0;
                    # 0.6s: release moderado — nivelamento suave entre falas.
                    "Release time (s)"         = 0.6;
                    # 1.0: ratio rápido no máximo — pega transientes de voz.
                    "Fast compression ratio"   = 1.0;
                    # 0.99: compressão quase total — tudo no mesmo patamar.
                    "Compression ratio"        = 0.99;
                  };
                }

                # ── Stage 1b: Dyson Compressor — canal direito ───────────
                {
                  type   = "ladspa";
                  name   = "leveler_r";
                  plugin = "dyson_compress_1403";
                  label  = "dysonCompress";
                  control = {
                    "Peak limit (dB)"          = -8.0;
                    "Release time (s)"         = 0.6;
                    "Fast compression ratio"   = 1.0;
                    "Compression ratio"        = 0.99;
                  };
                }

                # ── Stage 2: SC4 Stereo Compressor ───────────────────────
                {
                  type   = "ladspa";
                  name   = "compressor";
                  plugin = "sc4_1882";
                  label  = "sc4";
                  control = {
                    "RMS/peak"              = 0.5;
                    # 5ms: evita oscilação de ganho audível como crackle.
                    "Attack time (ms)"      = 5.0;
                    "Release time (ms)"     = 250.0;
                    "Threshold level (dB)"  = -30.0;
                    "Ratio (1:n)"           = 20.0;
                    "Knee radius (dB)"      = 1.0;
                    "Makeup gain (dB)"      = 10.0;
                  };
                }

                # ── Stage 3: Fast Lookahead Limiter ──────────────────────
                {
                  type   = "ladspa";
                  name   = "limiter";
                  plugin = "fast_lookahead_limiter_1913";
                  label  = "fastLookaheadLimiter";
                  control = {
                    "Input gain (dB)"    = 0.0;
                    "Limit (dB)"         = -8.0;
                    # 0.2s: release ultra-rápido (0.01s) gerava pumping/crackle
                    # quando o limiter batia no teto com compressão agressiva.
                    "Release time (s)"   = 0.2;
                  };
                }
              ];

              links = [
                { output = "leveler_l:Output";        input = "compressor:Left input";  }
                { output = "leveler_r:Output";        input = "compressor:Right input"; }
                { output = "compressor:Left output";  input = "limiter:Input 1";        }
                { output = "compressor:Right output"; input = "limiter:Input 2";        }
              ];

              inputs  = [ "leveler_l:Input" "leveler_r:Input" ];
              outputs = [ "limiter:Output 1" "limiter:Output 2" ];
            };

            "capture.props" = {
              "node.name"         = "voice_normalizer_sink";
              "media.class"       = "Audio/Sink";
              "audio.channels"    = 2;
              "audio.position"    = [ "FL" "FR" ];
              "audio.rate"        = 48000;

              "node.force-quantum" = 64;
              "node.latency"       = "64/48000";

              "node.always-process" = true;
            };

            "playback.props" = {
              "node.name"            = "voice_normalizer_output";
              "audio.channels"       = 2;
              "audio.position"       = [ "FL" "FR" ];

              "node.passive"         = true;
              "node.dont-reconnect"  = false;
              "stream.dont-remix"    = true;
              "audio.rate"           = 48000;
              "node.force-quantum"   = 64;
              "node.latency"         = "64/48000";
            };
          };
        }
      ];
    };
  };
}
