# gst-interp.nix — Módulo NixOS para o player de interpolação zero-copy
#
# Configura as variáveis de ambiente necessárias para:
#   1. GStreamer encontrar os plugins VA-API e Vulkan (gst-plugins-bad)
#   2. Mesa/radv ser selecionado como ICD Vulkan (garante radv, não lavapipe)
#   3. VA-API usar o driver correto (radeonsi) para a RX 9070
#   4. Mesa DRI não aplicar software fallback

{ pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # Variáveis de sessão (disponíveis para todos os processos do usuário)
  # ---------------------------------------------------------------------------
  environment.sessionVariables = {

    # Garante que o GStreamer encontra os plugins vulkan* e va* do gst-plugins-bad.
    # Sem isso, `vulkanupload`, `vulkansink`, `vulkancolorconvert`, `vah264dec`, etc.
    # não são encontrados pelo registry.
    GST_PLUGIN_PATH = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
      pkgs.gst_all_1.gst-plugins-bad
      pkgs.gst_all_1.gst-plugins-base
      pkgs.gst_all_1.gst-plugins-good
    ];

    # Força o Mesa radv como ICD Vulkan.
    # Sem isso, em sistemas com múltiplos ICDs, o Vulkan loader pode selecionar
    # lavapipe (software) ou outro ICD em vez da RX 9070.
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";

    # Driver VA-API: radeonsi (Mesa GalliumDriver para AMD)
    # Necessário para vah264dec/vah265dec usar aceleração hardware da RX 9070.
    LIBVA_DRIVER_NAME = "radeonsi";

    # Mesa: desativa software fallback (fail rápido se VA-API não funcionar)
    # Útil para debug. Comente em produção se quiser fallback gracioso.
    # LIBVA_MESSAGING_LEVEL = "1";  # Verbose VA-API logging — descomentar para debug
  };

  # ---------------------------------------------------------------------------
  # Dependências de sistema para VA-API + Vulkan
  # ---------------------------------------------------------------------------
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # necessário para alguns elementos GStreamer 32-bit

    # Garante que os drivers Mesa estão disponíveis via DRI
    # (já configurado em amd-gpu.nix, mas explicitamos aqui para clareza)
    extraPackages = with pkgs; [
      mesa                    # libGL, libEGL, radeonsi VA-API driver
      libva-utils             # vainfo — útil para diagnosticar VA-API
      vulkan-tools            # vulkaninfo, vkcube — diagnóstico Vulkan
      pkgs.gst_all_1.gst-vaapi  # plugin VA-API legacy (fallback)
    ];
  };

  # ---------------------------------------------------------------------------
  # udev rules: garante que /dev/dri/renderD128 é acessível pelo usuário
  # (necessário para VA-API sem root)
  # ---------------------------------------------------------------------------
  # Nota: o grupo `video` já está no extraGroups do usuário alice em configuration.nix.
  # Esta regra é um backup explícito.
  services.udev.extraRules = ''
    # Acesso render node para VA-API (gst-interp, mpv, etc.)
    SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="video", MODE="0660"
  '';
}
