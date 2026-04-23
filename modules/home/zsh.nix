{
  config,
  lib,
  pkgs,
  ...
}:

let
  fzfTabSrc = pkgs.fetchFromGitHub {
    owner = "Aloxaf";
    repo = "fzf-tab";
    rev = "v1.1.2";
    hash = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
  };

  zshAutopairSrc = pkgs.fetchFromGitHub {
    owner = "hlissner";
    repo = "zsh-autopair";
    rev = "449a7c3d095bc8f3d78cf37b9549f8bb4c383f3d";
    hash = "sha256-3zvOgIi+q7+sTXrT+r/4v98qjeiEL4Wh64rxBYnwJvQ=";
  };
in
{
  home.packages = [
    pkgs.starship
    pkgs.fzf
    pkgs.jq
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "emacs";

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
      append = true;
      share = true;
      ignoreDups = true;
    };

    # zsh-history-substring-search via nixpkgs; bindkeys base em mkOrder 1250 (HM)
    historySubstringSearch.enable = true;

    shellAliases = {
      # Fedora / RPM (útil em máquinas remotas ou hábito de teclado)
      dnfi = "sudo dnf install -y";
      dnfr = "sudo dnf remove";
      dnfu = "sudo dnf upgrade";

      grep = "grep --color=auto";
      ls = "ls -la --color=auto";
      gs = "git status";
      zshrc = ''nano "''${ZDOTDIR:-$HOME}/.zshrc"'';
      janelas = ''hyprctl clients -j | jq -r ".[] | \"Class: \\(.class) | Title: \\(.initialTitle)\""'';
    };

    plugins = [
      { name = "zsh-autopair"; src = zshAutopairSrc; }
      { name = "fzf-tab"; src = fzfTabSrc; }
    ];

    sessionVariables = {
      EDITOR = "nano";
      VISUAL = "code";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        eval "$(starship init zsh)"
      '')

      # Antes da ordem 900 (source dos plugins), para o fzf-tab ver o menu select
      (lib.mkOrder 850 ''
        zstyle ':completion:*' menu select=long
      '')

      (lib.mkOrder 1000 ''
        # Hyprland: assinatura da instância em runtime
        export HYPRLAND_INSTANCE_SIGNATURE="$(ls -1 "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/hypr 2>/dev/null | head -n1)"

        # terminfo para Home / End / Delete (Kitty, VTE, xterm, …)
        zmodload zsh/terminfo 2>/dev/null || true
        if [[ -n "$terminfo[khome]" ]]; then bindkey -- "$terminfo[khome]" beginning-of-line; fi
        if [[ -n "$terminfo[kend]" ]]; then bindkey -- "$terminfo[kend]" end-of-line; fi
        if [[ -n "$terminfo[kdch1]" ]]; then bindkey -- "$terminfo[kdch1]" delete-char; fi
        # sequências explícitas (fallbacks comuns)
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line
        bindkey '^[OH' beginning-of-line
        bindkey '^[OF' end-of-line
        bindkey '^[[1~' beginning-of-line
        bindkey '^[[4~' end-of-line
        bindkey '^[[3~' delete-char

        # Ctrl+Delete (Kitty: ^[[3;5~) — apagar palavra à frente
        bindkey '^[[3;5~' kill-word
        # Ctrl+← / Ctrl+→
        bindkey '^[[1;5D' backward-word
        bindkey '^[[1;5C' forward-word
        bindkey '^[Od' backward-word
        bindkey '^[Oc' forward-word

        # Ctrl+Backspace / Ctrl+H
        bindkey '^H' backward-kill-word
        bindkey '^?' backward-kill-word

        bindkey '^Z' undo

        # Auto start Hyprland no tty1 (usa start-hyprland); no fim para keybinds aplicarem antes do exec
        if [[ -z "$DISPLAY" && -n "$XDG_VTNR" && "$XDG_VTNR" -eq 1 ]]; then
          mkdir -p ~/.cache
          exec start-hyprland > ~/.cache/hyprland.log 2>&1
        fi
      '')

      # Depois de history-substring-search (ordem 1250 no HM): setas com terminfo alternativo
      (lib.mkOrder 1300 ''
        zmodload zsh/terminfo 2>/dev/null || true
        [[ -n "$terminfo[kcuu1]" ]] && bindkey -- "$terminfo[kcuu1]" history-substring-search-up
        [[ -n "$terminfo[kcud1]" ]] && bindkey -- "$terminfo[kcud1]" history-substring-search-down
      '')
    ];
  };

  xdg.configFile = {
    "starship.toml" = {
      source = ../../config/starship.toml;
      force = true;
    };
  };
}
