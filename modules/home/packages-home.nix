# Ferramentas de sessão do usuário (pkgs base — grupo "Sistema").
# Programas (apps) ficam em modules/nixos/programs.nix.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wl-clipboard
    wl-clipboard-x11
    cliphist
    grim
    slurp
    wf-recorder
    libnotify
  ];
}
