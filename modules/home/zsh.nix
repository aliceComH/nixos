{ pkgs, ... }:

{
  home.packages = [ pkgs.starship ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      eval "$(starship init zsh)"

      if [ -f ~/.config/zshrc.d/shortcuts.zsh ]; then
        source ~/.config/zshrc.d/shortcuts.zsh
      fi
      if [ -f ~/.config/zshrc.d/auto-Hypr.sh ]; then
        source ~/.config/zshrc.d/auto-Hypr.sh
      fi

      export EDITOR='nano'
      export VISUAL='code'
      export HYPRLAND_INSTANCE_SIGNATURE="$(ls -1 "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/hypr 2>/dev/null | head -n1)"

      alias grep='grep --color=auto'
      alias ls='ls -la --color=auto'
      alias gs='git status'
      alias zshrc='nano ~/.zshrc'
      alias janelas='hyprctl clients -j | jq -r ".[] | \"Class: \(.class) | Title: \(.initialTitle)\""'
    '';
  };

  # Paths relativos ao módulo: avaliação pura do flake não pode ler /etc/nixos via string.
  xdg.configFile = {
    "starship.toml" = {
      source = ../../config/starship.toml;
      force = true;
    };
    "zshrc.d/shortcuts.zsh" = {
      source = ../../home/zshrc.d/shortcuts.zsh;
      force = true;
    };
    "zshrc.d/auto-Hypr.sh" = {
      source = ../../home/zshrc.d/auto-Hypr.sh;
      force = true;
    };
  };
}
