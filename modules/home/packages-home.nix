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
