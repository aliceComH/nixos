# Tema GTK via dconf. No Wayland o GTK3 lê tema e ícones do gsettings
# (org.gnome.desktop.interface) e ignora as chaves equivalentes do
# ~/.config/gtk-3.0/settings.ini; sem isto ele cai no padrão "Adwaita" (claro,
# sem ícones instalados). Mantenha em sincronia com config/gtk-{3,4}.0/settings.ini.
# O pacote dos ícones fica em modules/nixos/packages-system.nix.
{ ... }:

{
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
    icon-theme = "Colloid-Dark";
  };
}
