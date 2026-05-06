# HTTPS na borda: apenas o path /qwen (Basic Auth) faz reverse proxy para Ollama local.
# Define `llm.edge.fqdn` e `llm.edge.acmeEmail` em hosts/.../configuration.nix (DNS A → IP público, port forward 443→este host).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.llm.edge;

  inherit (lib) escapeShellArg mkEnableOption mkIf mkMerge mkOption optional removeSuffix types;

  basicUser = "qwen";
  basicPassword = "Qigs&T1Tgtx*D%Fx";

in

{
  options.llm.edge = {
    enable = mkEnableOption "reverse proxy HTTPS /qwen → Ollama (WAN)" // {
      default = true;
      description = ''
        Liga Caddy na FQDN pública com TLS (ACME/Let's Encrypt) e expõe só /qwen com Basic Auth.
        Requer DNS e port forward TCP 443 (e HTTP 80 para o desafio ACME).
      '';
    };

    fqdn = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "llm.example.duckdns.org";
      description = ''
        Nome DNS público apontando para este host. Se for `null`, o bloco Caddy não é activado
        (podes usar só Ollama na LAN :11434).
      '';
    };

    acmeEmail = mkOption {
      type = types.str;
      default = "";
      description = "Email para a conta ACME (Let's Encrypt). Recomendado para avisos de expiração.";
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && cfg.fqdn != null && cfg.fqdn != "") (
      let
        qwenBasicHash = removeSuffix "\n" (
          builtins.readFile (
            pkgs.runCommand "llm-caddy-bcrypt-qwen" {
              nativeBuildInputs = [ pkgs.caddy ];
            } ''
              ${pkgs.caddy}/bin/caddy hash-password --plaintext ${escapeShellArg basicPassword} > "$out"
            ''
          )
        );

        proxyBlock = ''
          encode zstd gzip

          @qwenExact path /qwen
          redir @qwenExact /qwen/ 308

          handle_path /qwen/* {
            basic_auth {
              ${basicUser} ${qwenBasicHash}
            }
            reverse_proxy 127.0.0.1:${toString config.services.ollama.port} {
              header_up Host {host}
              transport http {
                keepalive 180s
              }
            }
          }

          handle {
            respond "LLM gateway: usa o path /qwen" 404
          }
        '';
      in
      {
        assertions = [
          {
            assertion = config.services.ollama.enable;
            message = "llm.edge requer services.ollama.enable = true (importe modules/nixos/llm/ollama.nix).";
          }
          {
            assertion = cfg.acmeEmail != "";
            message = "llm.edge.acmeEmail não pode ser vazio quando llm.edge.fqdn está definido.";
          }
        ];

        services.caddy = {
          enable = true;
          email = cfg.acmeEmail;
          openFirewall = true;

          virtualHosts.${cfg.fqdn} = {
            extraConfig = proxyBlock;
          };
        };
      }
    ))

    {
      warnings = optional (cfg.enable && (cfg.fqdn == null || cfg.fqdn == "")) ''
        llm.edge está activo mas llm.edge.fqdn não foi definido: o proxy HTTPS /qwen (Caddy) fica desligado.
        Define llm.edge.fqdn e llm.edge.acmeEmail em configuration.nix para expor /qwen na Internet.
      '';
    }
  ];
}
