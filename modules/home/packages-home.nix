{ pkgs, ... }:

{
  home.packages = with pkgs; [
    vesktop
    wl-clipboard
    grim
    slurp
    wf-recorder
    libnotify
  ];
}
