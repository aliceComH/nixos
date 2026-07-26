# Piper + libratbag: remapeamento de botões do Logitech G502 Hero.
# O serviço ratbagd expõe o hardware via D-Bus; piper é a GUI GTK.
{ pkgs, ... }:

{
  # Habilita o daemon ratbagd (libratbag) como serviço systemd.
  # Isso também registra as regras udev necessárias para acesso ao dispositivo.
  services.ratbagd.enable = true;

  # Piper (GUI) como pacote de sistema.
  environment.systemPackages = [ pkgs.piper ];
}
