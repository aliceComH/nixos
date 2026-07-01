{ config, pkgs, ... }:

let
  killswitchScript = "/etc/nixos/config/hypr/hyprland/scripts/adblock-killswitch.sh";
in
{
  services.unbound = {
    enable = true;
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

        msg-cache-size = "50m";
        rrset-cache-size = "100m";

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
