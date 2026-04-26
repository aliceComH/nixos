# Flatpaks (Flathub) aplicados na activação do Home Manager após o switch.
{ lib, pkgs, ... }:

{
  # Subshell: o PATH extra para o flatpak não "escapa" e estraga o PATH das
  # etapas seguintes da activação (nix-env, grep, find, gettext, ...).
  home.activation.installFlathubApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
      export PATH="${lib.makeBinPath [ pkgs.flatpak pkgs.coreutils ]}:$PATH"
      # --user: evita prompt de polkit durante a activação (sem root/TTY).
      flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
      flatpak remote-add --user --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo || true
      for app in \
        com.jetbrains.DataGrip \
        com.spotify.Client \
        com.stremio.Stremio \
        com.vysp3r.ProtonPlus \
        io.missioncenter.MissionCenter \
        org.qbittorrent.qBittorrent \
        com.discordapp.DiscordCanary
      do
        remote="flathub"
        if [ "$app" = "com.discordapp.DiscordCanary" ]; then
          remote="flathub-beta"
        fi
        flatpak install --user -y --noninteractive "$remote" "$app" || true
      done
      flatpak override --user --socket=wayland com.discordapp.DiscordCanary || true
    )
  '';
}
