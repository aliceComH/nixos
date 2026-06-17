# Derivação para o plugin VapourSynth-RIFE-ncnn-Vulkan (styler00dollar)
# RIFE: Real-Time Intermediate Flow Estimation — interpolação de frames via GPU (Vulkan)
{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  cmake,
  pkg-config,
  vapoursynth,
  vulkan-headers,
  vulkan-loader,
  glslang,
  ncnn,

}:

stdenv.mkDerivation rec {
  pname = "vapoursynth-rife-ncnn-vulkan";
  version = "r9_mod_v33";

  src = fetchFromGitHub {
    owner = "styler00dollar";
    repo = "VapourSynth-RIFE-ncnn-Vulkan";
    rev = "c3ec6aabc07c8fa37a4f58d7fed9e2ad1fc1b13f";
    hash = "sha256-j1ETwr8DF+EOThDOzF5OMHWoFmRD4gNW/tSj6f/n1Vk=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    meson
    ninja
    cmake    # ncnn subproject usa cmake via meson cmake.subproject()
    pkg-config
    glslang  # Para compilar shaders SPIR-V do ncnn
  ];

  buildInputs = [
    vapoursynth
    vulkan-headers
    vulkan-loader
    ncnn
  ];

  # O meson.build do projeto usa 'use_system_ncnn' como opção.
  # false = compila o ncnn bundled (submodule) com Vulkan habilitado.
  mesonFlags = [
    "-Duse_system_ncnn=true"
  ];

  # Fix Nix: o meson.build original calcula install_dir a partir do pkg-config
  # do VapourSynth, que aponta pro path read-only no nix store.
  # Reescrevemos para usar prefix/libdir do $out desta derivação.
  postPatch = ''
    substituteInPlace meson.build \
      --replace-fail "vapoursynth_dep.get_variable(pkgconfig: 'libdir') / 'vapoursynth'" \
                     "get_option('prefix') / get_option('libdir') / 'vapoursynth'"
  '';

  meta = with lib; {
    description = "RIFE ncnn Vulkan plugin for VapourSynth — AI frame interpolation on GPU";
    homepage = "https://github.com/styler00dollar/VapourSynth-RIFE-ncnn-Vulkan";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
