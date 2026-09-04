# LACT — Linux GPU Configuration Tool (AMD/NVIDIA)
# GUI em ALT+F3 (keybinds.lua). Daemon lactd expõe controle de clock/power.
#
# Nota: o lact 0.9.1 do nixpkgs quebrava com libdisplay-info 0.4.0 e exigia
# um pin em pkgs/lact/package.nix. A partir do lact 0.10.0 (nixpkgs
# atualizado em 2026-08) o upstream já não expõe/precisa desse override —
# o pacote padrão volta a compilar sem workaround.
{ ... }:

{
  services.lact.enable = true;
}
