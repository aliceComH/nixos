# Firefox como browser principal + native host do PWAsForFirefox (firefoxpwa).
# O Chrome fica instalado no sistema até a migração de favoritos; não é default.
{ pkgs, lib, config, repoRoot, ... }:

let
  link = rel: config.lib.file.mkOutOfStoreSymlink "${repoRoot}/${rel}";
  # Perfil partilhado criado pelo firefoxpwa (ulid de zeros).
  pwaProfile = "firefoxpwa/profiles/00000000000000000000000000";
in
{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.firefoxpwa ];
    policies.ExtensionSettings."firefoxpwa@filips.si" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/pwas-for-firefox/latest.xpi";
    };
    # Cubeb → PipeWire: ver config/firefoxpwa/user.js (mesmo valor nas PWAs).
    profiles.default.settings = {
      "media.volume_scale" = 3.0;
      "media.default_volume" = 1.0;
    };
  };

  # O .desktop do HM tem Exec=firefox (relativo). O xdg-desktop-portal corre com
  # PATH mínimo e falha; o Electron/Discord cai no Chrome, cujo Exec é absoluto.
  xdg.desktopEntries.firefox = {
    name = "Firefox";
    genericName = "Web Browser";
    exec = "${config.programs.firefox.finalPackage}/bin/firefox %U";
    icon = "firefox";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    startupNotify = true;
    settings.StartupWMClass = "firefox";
  };

  home.packages = [ pkgs.firefoxpwa ];

  # user.js não é reescrito pelo Firefox; userChrome.css esconde a icon bar
  # (CSD bugado no Hyprland). force: o perfil já existe com ficheiros gerados.
  xdg.dataFile."${pwaProfile}/user.js" = {
    source = link "config/firefoxpwa/user.js";
    force = true;
  };
  xdg.dataFile."${pwaProfile}/chrome/userChrome.css" = {
    source = link "config/firefoxpwa/userChrome.css";
    force = true;
  };

  home.activation.firefoxpwaChrome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="$HOME/.local/share/firefoxpwa/config.json"
    if [ -f "$cfg" ]; then
      ${pkgs.jq}/bin/jq '.config.runtime_enable_wayland = true' "$cfg" > "$cfg.tmp" \
        && mv "$cfg.tmp" "$cfg"
    fi
    xul="$HOME/.local/share/firefoxpwa/profiles/00000000000000000000000000/xulstore.json"
    if [ -f "$xul" ]; then
      ${pkgs.jq}/bin/jq \
        '.["chrome://browser/content/browser.xhtml"].TabsToolbar.collapsed = "true"' \
        "$xul" > "$xul.tmp" && mv "$xul.tmp" "$xul"
    fi
  '';
}
