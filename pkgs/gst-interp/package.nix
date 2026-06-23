# gst-interp — Zero-copy frame interpolation player
# GStreamer pipeline: VA-API decode → VkImage (DMA-BUF) → Ping-Pong VRAM → Compute Shader → vulkansink
#
# Build system: rustPlatform.buildRustPackage
# Shader compilation: glslang (GLSL → SPIR-V) invocado pelo build.rs
#
# NOTA: nixpkgs desabilita Vulkan no gst-plugins-bad explicitamente:
#   mesonFlags += [ "-Dvulkan=disabled" ]
# com o comentário "we haven't figured out yet which of the vulkan nixpkgs it needs".
# Esta derivação cria um override local com Vulkan habilitado.
{
  lib,
  rustPlatform,
  pkg-config,
  gst_all_1,
  vulkan-loader,
  vulkan-headers,
  libva,
  libva-utils,
  wayland,
  wayland-protocols,
  libdrm,
  glslang,
  clang,
  python3,
  makeWrapper,
}:

let
  # Override de gst-plugins-bad com Vulkan explicitamente habilitado.
  # nixpkgs upstream desabilita Vulkan com "-Dvulkan=disabled" porque não sabe
  # quais pacotes Vulkan usar. Nós sabemos:
  #   - nativeBuildInputs: glslang, python3 (para compilar shaders internos do plugin)
  #   - buildInputs: vulkan-loader + vulkan-headers (runtime Vulkan)
  gst-plugins-bad-vulkan = gst_all_1.gst-plugins-bad.overrideAttrs (old: {
    # glslang deve ser nativeBuildInput (ferramenta de compilação, não lib runtime)
    # python3 também é necessário para o script bin2array.py
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
      glslang
      python3
    ];

    buildInputs = (old.buildInputs or []) ++ [
      vulkan-loader
      vulkan-headers
    ];

    # O script bin2array.py tem um shebang #!/usr/bin/env python3
    # No sandbox do Nix, /usr/bin/env não existe. Precisamos forçar o patchShebangs.
    postPatch = (old.postPatch or "") + ''
      if [ -f ext/vulkan/shaders/bin2array.py ]; then
        patchShebangs ext/vulkan/shaders/bin2array.py
      fi
    '';

    mesonFlags = lib.filter
      (f: f != "-Dvulkan=disabled")  # Remove a flag que desabilita Vulkan
      (old.mesonFlags or [])
    ++ [ "-Dvulkan=enabled" ];       # Habilita explicitamente
  });


in
rustPlatform.buildRustPackage {
  pname = "gst-interp";
  version = "0.1.0";

  src = ./src;

  cargoHash = "sha256-fLgGe3UtszsnEnXVj5CAWOxbZKwuFp4jE4UOMQf5+kM=";

  nativeBuildInputs = [
    pkg-config
    glslang    # glslang binário invocado pelo build.rs para compilar shaders GLSL → SPIR-V
    clang      # para bindgen se necessário no futuro
    makeWrapper
  ];

  buildInputs = [
    # GStreamer core + plugins
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst-plugins-bad-vulkan  # override local com -Dvulkan=enabled
    gst_all_1.gst-plugins-good  # parsebin helpers

    # Vulkan
    vulkan-loader
    vulkan-headers
    # vulkan-validation-layers  # descomente para desenvolvimento/debug

    # VA-API (decodificação hardware)
    libva

    # Wayland (para vulkansink criar a janela)
    wayland
    wayland-protocols

    # DRM/KMS (para DMA-BUF interop)
    libdrm
  ];

  # Expõe os headers Vulkan para o build.rs e para ash
  VULKAN_SDK = vulkan-loader;

  # glslang precisa ser encontrado pelo build.rs
  GLSLANG_VALIDATOR = "${glslang}/bin/glslang";

  # Garante que o linker encontra a libvulkan.so da Mesa (radv)
  LD_LIBRARY_PATH = lib.makeLibraryPath [ vulkan-loader ];

  # Após instalar, define GST_PLUGIN_PATH para incluir nosso plugin
  # (o elemento InterpElement é registrado como plugin GStreamer embutido no binário)
  postInstall = ''
    wrapProgram $out/bin/gst-interp \
      --prefix GST_PLUGIN_PATH : "${lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
        gst-plugins-bad-vulkan
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
      ]}" \
      --set VK_ICD_FILENAMES "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json" \
      --set LIBVA_DRIVER_NAME "radeonsi"
  '';

  meta = with lib; {
    description = "Zero-copy GStreamer + Vulkan Compute frame interpolation player (gst-interp)";
    longDescription = ''
      Player de vídeo com interpolação de frames zero-copy:
      VA-API decodifica H.264/H.265 → DMA-BUF exportado como VkImage (radv) →
      Ping-Pong buffer estático na VRAM (slots N-1, N, N+1) →
      Compute Shader GLSL/SPIR-V interpola → vulkansink exibe via Wayland.
      Nenhum byte sai da VRAM para a CPU durante a interpolação.
    '';
    homepage = "https://github.com/alice/gst-interp";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "gst-interp";
  };
}
