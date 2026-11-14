# osu! (lazer). Vem do input `nixpkgs-osu`, independente do resto — grupo "osu!"
# da Central de Updates. Atualizar só ele: nix flake update nixpkgs-osu
#
# O wrapper respeita .agents/rules/pipewire-quantum.md (quantum 32 via ALSA).
{ pkgs, pkgs-osu, ... }:

let
  osuLazerFast = pkgs.symlinkJoin {
    name = "osu-lazer-fast";
    paths = [ pkgs-osu.osu-lazer-bin ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Varre a pasta bin e injeta prioridade alta em todos os executáveis (incluindo o "osu!")
      # NOTA: PIPEWIRE_QUANTUM foi removido — o quantum 32/48000 já é configurado
      # globalmente em services.nix (context.properties). A variável de ambiente
      # forçava renegociação do graph inteiro, conflitando com Discord/WebRTC.
      for bin in $out/bin/*; do
        wrapProgram "$bin" \
          --set PIPEWIRE_LATENCY "32/48000" \
          --set PIPEWIRE_ALSA "{ alsa.format=S32_LE alsa.channels=2 alsa.rate=48000 alsa.buffer-bytes=512 alsa.period-bytes=256 }" \
          --run 'renice -n -15 $$ >/dev/null 2>&1 || true'
      done
    '';
  };
in
{
  environment.systemPackages = [ osuLazerFast ];

  # Lista exibida na Central de Updates (tools/updates/updates.py).
  local.updateGroups.osu = [ pkgs-osu.osu-lazer-bin ];
}
