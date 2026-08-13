# LACT com libdisplay-info 0.3.0 — o nixpkgs unstable traz 0.4.0, mas o crate
# Rust do lact (0.9.1) exige < 0.4.0 via pkg-config. Sem este pin o build quebra.
{ pkgs, fetchFromGitLab, ... }:

let
  libdisplay-info-0_3 = pkgs.libdisplay-info.overrideAttrs (_: {
    version = "0.3.0";
    src = fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "emersion";
      repo = "libdisplay-info";
      rev = "0.3.0";
      hash = "sha256-nXf2KGovNKvcchlHlzKBkAOeySMJXgxMpbi5z9gLrdc=";
    };
  });
in
pkgs.lact.override { libdisplay-info = libdisplay-info-0_3; }
