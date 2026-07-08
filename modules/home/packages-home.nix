{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    wl-clipboard
    wl-clipboard-x11
    cliphist
    grim
    slurp
    wf-recorder
    libnotify

    # --- Pacotes do Google Antigravity ---
    inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity
    inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity-ide
    inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity-cli
  ];
}