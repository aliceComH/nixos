{ config, pkgs, ... }:

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
        use-caps-for-id = true;

        # Ativa o Cache de mensagens e validação DNSSEC
        auto-trust-anchor-file = "/var/lib/unbound/root.key";
        prefetch = true;

        msg-cache-size = "50m";
        rrset-cache-size = "100m";
      };
    };
  };

  # Configura o sistema para usar a si mesmo como DNS
  networking.nameservers = [ "127.0.0.1" ];

  # Impede que o gerenciador de rede (NetworkManager/DHCP) mude o seu DNS
  networking.dhcpcd.enable = false; # Caso use dhcpcd
  networking.networkmanager.dns = "none";
}
