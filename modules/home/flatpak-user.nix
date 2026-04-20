# Flatpaks (Flathub) aplicados na activação do Home Manager após o switch.
{ lib, pkgs, ... }:

{
  # Subshell: o PATH extra para o flatpak não "escapa" e estraga o PATH das
  # etapas seguintes da activação (nix-env, grep, find, gettext, ...).
  home.activation.installFlathubApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
      export PATH="${lib.makeBinPath [ pkgs.flatpak pkgs.coreutils ]}:$PATH"
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
      for app in \
        com.jetbrains.DataGrip \
        com.spotify.Client \
        com.stremio.Stremio \
        com.vysp3r.ProtonPlus \
        io.missioncenter.MissionCenter \
        org.qbittorrent.qBittorrent
      do
        flatpak install -y --noninteractive flathub "$app" || true
      done
    )
  '';
}
