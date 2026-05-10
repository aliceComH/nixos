# Ollama com ROCm (AMD). GPU continua configurada em ../amd-gpu.nix — aqui só o runtime de inferência.
#
# Este módulo é LAN-only: não há exposição WAN aqui.
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
  searxSettings = pkgs.writeText "searxng-settings.yml" ''
    use_default_settings: true
    server:
      secret_key: "change-this-searx-secret"
      bind_address: "0.0.0.0"
      port: 8080
      base_url: "http://searxng:8080/"
      limiter: false
    search:
      safe_search: 0
      formats:
        - html
        - json
  '';
  llmPath = makeBinPath [
    pkgs.docker
    pkgs.curl
    pkgs.coreutils
    pkgs.ripgrep
  ];

  llm-start = pkgs.writeShellScriptBin "llm-start" ''
    set -euo pipefail
    export PATH="${llmPath}:/run/wrappers/bin''${PATH:+:$PATH}"
    if ! ${docker} network inspect llm-stack >/dev/null 2>&1; then
      ${docker} network create llm-stack >/dev/null
    fi
    ${docker} volume create open-webui-data >/dev/null
    ${docker} volume create searxng-cache >/dev/null
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

    # SearXNG fornece busca web para Open WebUI.
    if ${docker} container inspect searxng >/dev/null 2>&1; then
      if ! ${docker} inspect --format '{{json .NetworkSettings.Networks}}' searxng | rg -q '"llm-stack"'; then
        ${docker} network connect llm-stack searxng >/dev/null 2>&1 || true
      fi
      ${docker} start searxng >/dev/null
    else
      ${docker} run -d --name searxng --restart unless-stopped \
        --network llm-stack \
        -p 127.0.0.1:8080:8080 \
        -v "${searxSettings}:/etc/searxng/settings.yml:ro" \
        -v searxng-cache:/var/cache/searxng:rw \
        -e SEARXNG_BASE_URL=http://searxng:8080/ \
        --cap-drop ALL \
        --cap-add CHOWN \
        --cap-add SETGID \
        --cap-add SETUID \
        --cap-add DAC_OVERRIDE \
        searxng/searxng:latest >/dev/null
    fi
    searx_ok=0
    for _ in $(seq 1 80); do
      if curl -sfS "http://127.0.0.1:8080/search?q=healthcheck&format=json" >/dev/null 2>&1; then
        searx_ok=1
        break
      fi
      sleep 0.25
    done
    if [ "$searx_ok" -ne 1 ]; then
      echo "llm-start: SearXNG não respondeu em http://127.0.0.1:8080/search?q=healthcheck&format=json (vê docker logs searxng)" >&2
      exit 1
    fi

    openwebui_needs_recreate=0
    if ${docker} container inspect open-webui >/dev/null 2>&1; then
      openwebui_env="$(${docker} inspect --format '{{range .Config.Env}}{{println .}}{{end}}' open-webui)"
      case "$openwebui_env" in
        *"ENABLE_WEB_SEARCH=True"*) ;;
        *) openwebui_needs_recreate=1 ;;
      esac
      case "$openwebui_env" in
        *"WEB_SEARCH_ENGINE=searxng"*) ;;
        *) openwebui_needs_recreate=1 ;;
      esac
      case "$openwebui_env" in
        *"SEARXNG_QUERY_URL=http://searxng:8080/search?q=<query>&format=json"*) ;;
        *) openwebui_needs_recreate=1 ;;
      esac
    fi

    if [ "$openwebui_needs_recreate" -eq 1 ]; then
      ${docker} rm -f open-webui >/dev/null 2>&1 || true
    fi

    # `docker ps --format` falhou em alguns setups; `container inspect` é fiável para nome existente
    if ${docker} container inspect open-webui >/dev/null 2>&1; then
      if ! ${docker} inspect --format '{{json .NetworkSettings.Networks}}' open-webui | rg -q '"llm-stack"'; then
        ${docker} network connect llm-stack open-webui >/dev/null 2>&1 || true
      fi
      ${docker} start open-webui >/dev/null
    else
      ${docker} run -d --name open-webui --restart unless-stopped \
        --network llm-stack \
        --add-host=host.docker.internal:host-gateway \
        -p 0.0.0.0:3000:8080 \
        -v open-webui-data:/app/backend/data \
        -e OLLAMA_BASE_URL=http://host.docker.internal:${toString config.services.ollama.port} \
        -e ENABLE_WEB_SEARCH=True \
        -e WEB_SEARCH_ENGINE=searxng \
        -e WEB_SEARCH_RESULT_COUNT=5 \
        -e WEB_SEARCH_CONCURRENT_REQUESTS=10 \
        -e 'SEARXNG_QUERY_URL=http://searxng:8080/search?q=<query>&format=json' \
        ghcr.io/open-webui/open-webui:main >/dev/null
    fi

    # Open WebUI demora arrancar (migrações, downloads HF, etc.); espera /health ficar disponível antes de considerar pronto.
    openwebui_http_code=""
    for _ in $(seq 1 600); do
      openwebui_http_code="$(curl -s -o /dev/null -w '%{http_code}' 'http://127.0.0.1:3000/health' 2>/dev/null || printf '000')"
      if [ "$openwebui_http_code" = "200" ]; then
        break
      fi
      sleep 0.5
    done
    if [ "$openwebui_http_code" != "200" ]; then
      echo "llm-start: Open WebUI não ficou pronta em http://127.0.0.1:3000/health dentro do tempo esperado (último código: $openwebui_http_code; esperado 200)" >&2
      exit 1
    fi
  '';

  llm-stop = pkgs.writeShellScriptBin "llm-stop" ''
    set -euo pipefail
    export PATH="${llmPath}:/run/wrappers/bin''${PATH:+:$PATH}"
    ${docker} stop open-webui 2>/dev/null || true
    ${docker} stop searxng 2>/dev/null || true
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
  # SearXNG fica só em localhost :8080 para uso interno do host/containers.
  networking.firewall.allowedTCPPorts = lib.mkAfter [
    config.services.ollama.port
    3000
  ];

  environment.systemPackages = [
    llm-start
    llm-stop
  ];
}
