{ config, pkgs, ... }:

let
  killswitchScript = "/etc/nixos/config/hypr/hyprland/scripts/adblock-killswitch.sh";
  updateScript = "/etc/nixos/config/hypr/hyprland/scripts/update-blocklist.sh";
in
{
  services.unbound = {
    enable = true;
    # Socket local para `unbound-control` (stats, flush, etc.). Só root/unbound acessam.
    localControlSocketPath = "/run/unbound/unbound.ctl";
    settings = {
      server = {
        # Escuta apenas na própria máquina (localhost)
        interface = [ "127.0.0.1" ];
        port = 53;

        # Permite conexões apenas locais
        access-control = [ "127.0.0.0/8 allow" ];

        # Otimizações de privacidade e segurança
        hide-identity = true;
        hide-version = true;
        use-caps-for-id = false; # Desativado para evitar timeouts com servidores mal configurados

        # Ativa o Cache de mensagens e validação DNSSEC
        auto-trust-anchor-file = "/var/lib/unbound/root.key";
        prefetch = true;
        serve-expired = true; # Serve respostas do cache expirado enquanto atualiza em background para latência zero na percepção do usuário

        # Serve o expirado NA HORA (0 = não espera o upstream) e renova em
        # background; no máximo 1 dia de idade para não servir IP morto.
        serve-expired-client-timeout = 0;
        serve-expired-ttl = 86400;
        prefetch-key = true; # busca DNSKEY junto, poupa uma ida ao upstream na validação

        # Cache grande: sobra RAM, e cada hit evita um round-trip TLS.
        msg-cache-size = "128m";
        rrset-cache-size = "256m"; # regra do unbound: ~2x o msg-cache
        key-cache-size = "64m";
        neg-cache-size = "16m";

        # Paralelismo: 4 threads, slabs em potência de 2 >= threads (menos
        # contenção de lock), um socket por thread.
        num-threads = 4;
        msg-cache-slabs = 4;
        rrset-cache-slabs = 4;
        infra-cache-slabs = 4;
        key-cache-slabs = 4;
        so-reuseport = true;
        outgoing-range = 8192;
        num-queries-per-thread = 4096;

        # Menos idas ao upstream e respostas menores.
        aggressive-nsec = true; # responde NXDOMAIN de zonas assinadas a partir do cache NSEC
        minimal-responses = true;
        edns-buffer-size = 1232; # evita fragmentação UDP

        # Mantém as conexões TLS com o upstream abertas por mais tempo: o custo
        # de um cache miss é quase todo o handshake TLS quando a conexão caiu.
        tcp-reuse-timeout = 300000; # ms
        max-reuse-tcp-queries = 1000;

        # Pacote de certificados raiz para validar a conexão TLS com os servidores Quad9 e Cloudflare
        tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";

        # Ad-blocker: inclui regras de bloqueio de domínios geradas pelo update-blocklist.sh
        # O arquivo fica em /var/lib/unbound/ porque o systemd ProtectSystem=strict
        # impede escrita em /etc/unbound/ — só stateDir (/var/lib/unbound) é read-write.
        include = ''"/var/lib/unbound/adblock.conf"'';
      };

      # Encaminha as requisições não cacheadas via DNS-over-TLS na porta 853
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = true;
          forward-addr = [
            # Quad9 (Primário - Foco em privacidade e segurança)
            "9.9.9.9@853#dns.quad9.net"
            "149.112.112.112@853#dns.quad9.net"
            
            # Cloudflare (Secundário - Foco em velocidade/backup)
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
          ];
        }
      ];
    };
  };

  # Garante que os arquivos de blocklist existam antes do unbound iniciar.
  # Sem isso, o unbound falha no boot ao tentar incluir um arquivo inexistente.
  systemd.tmpfiles.rules = [
    "f /var/lib/unbound/adblock.conf 0644 unbound unbound -"
    "f /var/lib/unbound/adblock_master.conf 0644 unbound unbound -"
  ];

  # Atualiza as blocklists toda semana (e no boot, se perdeu a janela).
  # O script valida a lista nova antes de trocar e só recarrega o unbound se o
  # bloqueio estiver ativo.
  systemd.services.unbound-blocklist-update = {
    description = "Atualiza as blocklists de anúncios do unbound";
    after = [ "network-online.target" "unbound.service" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ bash curl coreutils gnused gnugrep gawk config.services.unbound.package systemd ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${updateScript}";
    };
  };
  systemd.timers.unbound-blocklist-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # Permite que alice execute o killswitch sem senha via keybind do Hyprland
  security.sudo.extraRules = [
    {
      users = [ "alice" ];
      commands = [
        { command = killswitchScript; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  # Configura o sistema para usar a si mesmo como DNS
  networking.nameservers = [ "127.0.0.1" ];

  # Impede que o gerenciador de rede (NetworkManager/DHCP) mude o seu DNS
  networking.dhcpcd.enable = false; # Caso use dhcpcd
  networking.networkmanager.dns = "none";
}
