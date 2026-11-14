# Programas (apps de uso direto). Vêm do input `nixpkgs-apps`, independente do
# `nixpkgs` base — grupo "Programas" da Central de Updates.
# Atualizar só eles: nix flake update nixpkgs-apps claude-desktop bedrock-on-linux
# Ver .agents/knowledge/updates.md.
#
# Atenção: `pkgs-apps` NÃO recebe os overlays de `nixpkgs.overlays` (são do pkgs base).
# Ficam de fora, de propósito, no pkgs base:
#   - kitty e pavucontrol (packages-system.nix): o terminal é quem roda os updates,
#     não pode depender de um nixpkgs defasado em relação aos drivers;
#   - Steam e Thunar (services.nix, via programs.<x>.enable).
# Minecraft Bedrock tem módulo próprio (minecraft-bedrock.nix), mas pertence a este grupo.
{ pkgs, pkgs-apps, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  mpvSingleInstance = pkgs-apps.symlinkJoin {
    name = "mpv-single-instance";
    paths = [
      (pkgs-apps.mpv.override {
        mpv-unwrapped = pkgs-apps.mpv-unwrapped.override {
          vapoursynthSupport = true;
          vapoursynth = pkgs-apps.vapoursynth.withPlugins [
            pkgs-apps.vapoursynth-mvtools
            (pkgs-apps.callPackage ../../pkgs/vapoursynth-rife-ncnn-vulkan/package.nix {})
          ];
        };
      })
    ];
    buildInputs = [ pkgs-apps.makeWrapper pkgs-apps.luajitPackages.luasocket ];
    postBuild = ''
      wrapProgram $out/bin/mpv \
        --prefix LUA_PATH ";" "${pkgs-apps.luajitPackages.luasocket}/share/lua/5.1/?.lua;${pkgs-apps.luajitPackages.luasocket}/share/lua/5.1/?/init.lua" \
        --prefix LUA_CPATH ";" "${pkgs-apps.luajitPackages.luasocket}/lib/lua/5.1/?.so" \
        --run 'for p in $(pgrep -x mpv); do [ "$p" != "$$" ] && kill -9 "$p" 2>/dev/null || true; done'
    '';
  };

  apps =
    (with pkgs-apps; [
      google-chrome
      thunderbird
      vesktop
      vscodium # editor: árvore de arquivos + preview de Markdown (ALT + SHIFT + C)
      obsidian # notas / vault em ~/vault (ALT + O)
      imv
      gnome-calculator
      gnome-disk-utility
      file-roller
      wootility
      protontricks
      winetricks
    ])
    ++ [
      mpvSingleInstance
      inputs.claude-desktop.packages.${system}.claude-desktop
    ];
in
{
  environment.systemPackages = apps;

  # Lista exibida na Central de Updates (tools/updates/updates.py).
  local.updateGroups.programas = apps;
}
