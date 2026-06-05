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

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      default-sort-order = "mtime";
      default-sort-in-reverse-order = true;
    };
    
    "org/gnome/nautilus/list-view" = {
      use-tree-view = true;
    };
  };
}
