# Minecraft Bedrock da Microsoft Store (GDK / Windows) no Linux.
#
# Não é o APK Android (mcpelauncher). É o cliente Windows, descarregado
# da Store com a tua conta, a correr num prefix Wine gerido (WineGDK /
# GDK-Proton) pelo BedrockOnLinux.
#
# Vanilla `wine Minecraft.exe` da Store não funciona (UWP/GDK). Este
# launcher é o caminho Wine que a comunidade usa para essa licença.
#
# O jogo é D3D12 → vkd3d-proton → Vulkan no RADV. No Hyprland o Wine
# corre por XWayland, que por omissão usa present FIFO e parece um
# teto a 60 fps mesmo com gfx_max_framerate:0. MESA_VK_WSI_PRESENT_MODE
# immediate pede present async (tearing); o Hyprland só honra tearing
# com a janela fullscreen + windowrule `immediate`.
{ pkgs, inputs, ... }:

let
  bol = inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "bedrock-on-linux";
      paths = [ bol ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/bedrock-on-linux \
          --set-default MESA_VK_WSI_PRESENT_MODE immediate
      '';
    })
  ];
}
