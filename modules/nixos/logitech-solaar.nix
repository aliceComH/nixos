# Suporte a dispositivos Logitech wireless via Solaar (HID++).
# Habilita udev rules para comunicação com receivers Unifying/Bolt
# e instala o Solaar para controle de features como fn-swap.
{ pkgs, ... }:

{
  # udev rules para receivers Logitech (Unifying, Bolt, Nano).
  hardware.logitech.wireless.enable = true;

  environment.systemPackages = [ pkgs.solaar ];
}
