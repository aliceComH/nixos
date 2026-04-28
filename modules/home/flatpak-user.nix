# Flatpaks (Flathub) aplicados na activação do Home Manager após o switch.
#
# Vesktop (Flathub): cliente Discord com Vencord; pipeline de partilha de ecrã/áudio distinto
# do cliente oficial Chromium-only.
{ lib, pkgs, ... }:

{
  # Subshell: o PATH extra para o flatpak não "escapa" e estraga o PATH das
  # etapas seguintes da activação (nix-env, grep, find, gettext, ...).
  home.activation.installFlathubApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
      export PATH="${lib.makeBinPath [ pkgs.flatpak pkgs.coreutils ]}:$PATH"
      # --user: evita prompt de polkit durante a activação (sem root/TTY).
      flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
      flatpak uninstall --user -y --noninteractive com.discordapp.DiscordCanary 2>/dev/null || true
      for app in \
        com.jetbrains.DataGrip \
        com.spotify.Client \
        com.stremio.Stremio \
        com.vysp3r.ProtonPlus \
        dev.vencord.Vesktop \
        io.missioncenter.MissionCenter \
        org.qbittorrent.qBittorrent
      do
        flatpak install --user -y --noninteractive flathub "$app" || true
      done
      flatpak override --user --socket=wayland dev.vencord.Vesktop || true
    )
  '';
}
