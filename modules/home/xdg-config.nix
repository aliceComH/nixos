# Liga dotfiles do repositório (../config) em ~/.config via symlink fora da store.
# Requer permissão habitual do HM para mkOutOfStoreSymlink.
{ repoRoot, config, ... }:

let
  link = rel: config.lib.file.mkOutOfStoreSymlink "${repoRoot}/${rel}";
  # force: evita falha "would be clobbered" quando já existem pastas/cópias em ~/.config
  linkForce = rel: {
    source = link rel;
    force = true;
  };
in
{
  xdg.configFile = {
    "hypr" = linkForce "config/hypr";
    "kitty" = linkForce "config/kitty";
    "rofi" = linkForce "config/rofi";
    "gtk-3.0" = linkForce "config/gtk-3.0";
    "gtk-4.0" = linkForce "config/gtk-4.0";
    #    "environment.d" = linkForce "config/environment.d";
    "fastfetch" = linkForce "config/fastfetch";
    "Kvantum" = linkForce "config/Kvantum";
    "qt5ct" = linkForce "config/qt5ct";
    "qt6ct" = linkForce "config/qt6ct";
    "kde-material-you-colors" = linkForce "config/kde-material-you-colors";
    "xdg-desktop-portal" = linkForce "config/xdg-desktop-portal";
    "mpv" = linkForce "config/mpv";
  };
}
