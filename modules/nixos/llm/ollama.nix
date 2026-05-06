# Ollama com ROCm (AMD). GPU continua configurada em ../amd-gpu.nix — aqui só o runtime de inferência.
#
# Segurança WAN: não faças port forward da 11434 no router — usa só HTTPS :443 + /qwen (módulo edge.nix).
#
# Open WebUI (opcional, Docker já activo em services.nix); llm-start usa -p 0.0.0.0:3000 (acessível na LAN).
#   docker run -d --restart unless-stopped \
#     -p 0.0.0.0:3000:8080 \
#     -e OLLAMA_BASE_URL=http://172.17.0.1:11434 \
#     ghcr.io/open-webui/open-webui:main
# (ou OLLAMA_BASE_URL=http://HOST_LAN:11434 se o bridge não alcançar 172.17.0.1.)
{ config, lib, pkgs, ... }:

let
  inherit (lib) getExe makeBinPath mkForce;
  systemctl = "${config.systemd.package}/bin/systemctl";
  docker = getExe pkgs.docker;
  llmPath = makeBinPath [
    pkgs.docker
    pkgs.curl
    pkgs.coreutils
  ];

  llm-start = pkgs.writeShellScriptBin "llm-start" ''
    set -euo pipefail
    export PATH="${llmPath}:/run/wrappers/bin''${PATH:+:$PATH}"
    sudo ${systemctl} start ollama
    # Espera o socket HTTP (evita seguir com Ollama morto / ainda a subir)
    ollama_ok=0
    for _ in $(seq 1 80); do
      if curl -sfS "http://127.0.0.1:${toString config.services.ollama.port}/" >/dev/null 2>&1; then
        ollama_ok=1
        break
      fi
      sleep 0.25
    done
    if [ "$ollama_ok" -ne 1 ]; then
      echo "llm-start: Ollama não respondeu em http://127.0.0.1:${toString config.services.ollama.port}/ (vê journalctl -u ollama -b)" >&2
      exit 1
    fi
    # `docker ps --format` falhou em alguns setups; `container inspect` é fiável para nome existente
    if ${docker} container inspect open-webui >/dev/null 2>&1; then
      ${docker} start open-webui
    else
      ${docker} run -d --name open-webui --restart unless-stopped \
        -p 0.0.0.0:3000:8080 \
        -e OLLAMA_BASE_URL=http://172.17.0.1:${toString config.services.ollama.port} \
        ghcr.io/open-webui/open-webui:main
    fi
  '';

  llm-stop = pkgs.writeShellScriptBin "llm-stop" ''
    set -euo pipefail
    export PATH="${llmPath}:/run/wrappers/bin''${PATH:+:$PATH}"
    ${docker} stop open-webui 2>/dev/null || true
    sudo ${systemctl} stop ollama
  '';
in

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    host = "0.0.0.0";
    port = 11434;
    loadModels = [ "qwen2.5-coder:14b" ];
    openFirewall = false;
    # Se `rocminfo` / o serviço falhar a ver a RX 9070 (RDNA 4), tenta descomentar e ajustar conforme docs AMD / ollama gpu.md
    # rocmOverrideGfx = "12.0.0";
  };

  # Não arrancar Ollama no boot; usa `llm-start` / Hypr SUPER+SHIFT+F1.
  systemd.services.ollama.wantedBy = mkForce [ ];
  # Só puxa modelos quando o serviço Ollama é iniciado manualmente (evita unidade no multi-user.target).
  systemd.services.ollama-model-loader.wantedBy = mkForce [ "ollama.service" ];

  # LAN: Ollama :11434 + Open WebUI :3000 (sem auth na LAN). Não faças port forward destas portas na Internet.
  networking.firewall.allowedTCPPorts = lib.mkAfter [
    config.services.ollama.port
    3000
  ];

  environment.systemPackages = [
    llm-start
    llm-stop
  ];
}
