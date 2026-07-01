{ pkgs, ... }:

{
  # Autologin na consola (substitui o override manual de getty@tty1, que quebrava o ExecStart
  # oficial do NixOS: faltava --login-program e o wrapper correcto do módulo getty.nix).
  services.getty.autologinUser = "alice";

  fonts.packages = with pkgs; [
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    font-awesome
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap.enable = true;

  networking.networkmanager.enable = true;
  services.cloudflare-warp.enable = true;

  # Disques (gnome-disk-utility), Thunar-volman e montagens automáticas via D-Bus
  # precisam do udisks2 activo; sem o serviço a lista de discos fica vazia.
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Partições exFAT (p.ex. SSDs externos formatados no Windows).
  boot.supportedFilesystems = [ "exfat" ];

  # rtkit dá prioridade RT ao PipeWire sem precisar rodar como root.
  security.rtkit.enable = true;

  # PAM limits agressivos para o grupo audio.
  # Isso permite que processos do grupo audio (PipeWire, osu!, etc.) solicitem
  # scheduling real-time diretamente via syscall, sem depender do RTKit.
  # Sem isso, o RTKit limita a prio 20 — insuficiente para 64/48000.
  security.pam.loginLimits = [
    { domain = "@audio"; type = "-"; item = "rtprio";  value = "95";        }
    { domain = "@audio"; type = "-"; item = "nice";    value = "-20";       }
    { domain = "@audio"; type = "-"; item = "memlock"; value = "unlimited"; }
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;

    # Força o pipewire-pulse a também subir prioridade RT.
    # Por padrão o pipewire-pulse herda o config do módulo RT,
    # mas não solicita RT ao RTKit — com os PAM limits acima,
    # o módulo RT consegue setar SCHED_RR diretamente via syscall.
    extraConfig.pipewire-pulse."10-rt-priority" = {
      "context.modules" = [
        {
          name = "libpipewire-module-rt";
          args = {
            "nice.level"   = -15;
            "rt.prio"      = 88;
          };
          flags = [ "ifexists" "nofail" ];
        }
      ];
    };
  };
  services.pipewire.wireplumber.enable = true;

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  hardware.opentabletdriver.enable = true;

  systemd.user.services.opentabletdriver = {
    serviceConfig = {
      # Define a política de agendamento como FIFO (First-In, First-Out)
      # É a política padrão do kernel Linux para tarefas de tempo real.
      CPUSchedulingPolicy = "fifo";
      
      # Prioridade de 1 a 99. 89 é um "sweet spot" excelente.
      # Fica acima de quase tudo do sistema, mas abaixo dos threads
      # críticos de interrupção do hardware, evitando congelamentos.
      CPUSchedulingPriority = 89;
      
      # Eleva o limite máximo de prioridade RT que esse serviço pode solicitar
      LimitRTPRIO = 99;
    };
  };

  # Permite que o gerenciador systemd do usuário utilize prioridade de tempo real
  # e nice extremo, repassando para os serviços de usuário (PipeWire, etc.).
  systemd.services."user@".serviceConfig = {
    LimitRTPRIO = 95;
    LimitNICE = "nice:-20";   # Formato: nice:-20 = permite nice até -20
    LimitMEMLOCK = "infinity";
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  programs.steam.enable = true;

  services.tuned.enable = true;

  # Expoe/ativa unidade lactd a partir do pacote do LACT.
  systemd.packages = [ pkgs.lact ];
  systemd.services.lactd = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  programs.dconf.enable = true;

  programs.zsh.enable = true;

  programs.nix-ld = {
    enable = true;
    # libgbm.so.1 é necessário para o gatherer do Mission Center (flatpak)
    # correr fora do sandbox no host NixOS.
    libraries = with pkgs; [ libgbm ];
  };

  security.sudo.wheelNeedsPassword = false;
}
