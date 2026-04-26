{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wl-clipboard
    grim
    slurp
    wf-recorder
    libnotify
  ];
}
