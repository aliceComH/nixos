# Liga dotfiles do repositório (../config) em ~/.config via symlink fora da store.
# Requer permissão habitual do HM para mkOutOfStoreSymlink.
{ repoRoot, config, ... }:

let
  link = rel: config.lib.file.mkOutOfStoreSymlink "${repoRoot}/${rel}";
in
{
  xdg.configFile = {
    "hypr".source = link "config/hypr";
    "kitty".source = link "config/kitty";
    "rofi".source = link "config/rofi";
    "gtk-3.0".source = link "config/gtk-3.0";
    "gtk-4.0".source = link "config/gtk-4.0";
    "environment.d".source = link "config/environment.d";
    "fastfetch".source = link "config/fastfetch";
    "Kvantum".source = link "config/Kvantum";
    "qt5ct".source = link "config/qt5ct";
    "qt6ct".source = link "config/qt6ct";
    "kde-material-you-colors".source = link "config/kde-material-you-colors";
    "xdg-desktop-portal".source = link "config/xdg-desktop-portal";
  };
}
