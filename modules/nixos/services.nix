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

  # Disques (gnome-disk-utility) e montagens automáticas via D-Bus
  # precisam do udisks2 activo; sem o serviço a lista de discos fica vazia.
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Partições exFAT (p.ex. SSDs externos formatados no Windows).
  boot.supportedFilesystems = [ "exfat" ];

  # Desativa economy de energia do codec HDA Intel (placa onboard).
  # power_save=0: não entra em suspend após N segundos de silêncio.
  # power_save_controller=N: desabilita o controller-level power save.
  # Sem isso, o codec faz wake-up tardio e causa xruns nos primeiros
  # frames após silêncio (audível como click/pop no mirror da soundbar).
  boot.kernelParams = [
    "snd_hda_intel.power_save=0"
    "snd_hda_intel.power_save_controller=N"
  ];

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

    # ── Clock global: rate 48000, quantum 64 (~1.33ms), osu! opera em 32 ──
    # force-quantum=64: trava o quantum do driver/graph em 64. Nenhum
    #   cliente pode renegociar para cima (elimina quantum inflation).
    # force-rate=48000: trava o rate — streams a 44100 (osu!) são
    #   resampleados pelo adaptador, sem switch de rate no graph.
    # allowed-rates=[48000]: reforço extra — graph só opera em 48000.
    # min-quantum=32: permite que regras WirePlumber (osu!) peçam 32.
    # max-quantum=64: teto absoluto — impede loopbacks/clientes de
    #   inflarem para 1024/6144 como acontecia antes.
    # ⚠️  NÃO ALTERAR — ver .agents/rules/pipewire-quantum.md
    extraConfig.pipewire."10-clock" = {
      "context.properties" = {
        "default.clock.rate"           = 48000;
        "default.clock.allowed-rates"  = [ 48000 ];
        "default.clock.quantum"        = 64;
        "default.clock.min-quantum"    = 32;
        "default.clock.max-quantum"    = 64;
        "default.clock.force-quantum"  = 64;
        "default.clock.force-rate"     = 48000;
      };
    };

    # ── NOVO: Interceptação de nós ALSA através do WirePlumber ──
    wireplumber.extraConfig."11-alsa-force" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              # Alvo: Captura qualquer stream de áudio aberto pela camada ALSA
              "node.name" = "~alsa_playback.*";
            }
          ];
          actions = {
            update-props = {
              # Força a reamostragem a acontecer no adaptador do cliente,
              # entregando 48000Hz puros para o grafo.
              "audio.rate"            = 48000;
              "node.rate"             = "1/48000";
              "node.force-rate"       = 48000;
              
              # Tranca a latência requisitada em 32 samples
              "node.latency"          = "32/48000";
              "node.force-quantum"    = 32;
            };
          };
        }
      ];
    };

    # ── Prioridade RT do pipewire-pulse + quantum mínimo ──────────────────
    # Força o pipewire-pulse a subir prioridade RT via módulo RT.
    # pulse.min.quantum=32/48000: permite que a regra do osu! (force-quantum=32)
    # seja respeitada pela camada PulseAudio. Sem isso, o pulse clamparia a 64.
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
      "pulse.min.quantum" = "32/48000";
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

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.tumbler.enable = true;
  programs.xfconf.enable = true;

  services.tuned.enable = true;

  # Expoe/ativa unidade lactd a partir do pacote do LACT.
  # systemd.packages = [ pkgs.lact ];
  # systemd.services.lactd = {
  #   enable = true;
  #   wantedBy = [ "multi-user.target" ];
  # };

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
