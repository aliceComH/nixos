# Liga dotfiles do repositório (../config) em ~/.config via symlink fora da store.
# Requer permissão habitual do HM para mkOutOfStoreSymlink.
{ repoRoot, config, lib, ... }:

let
  link = rel: config.lib.file.mkOutOfStoreSymlink "${repoRoot}/${rel}";
  # force: evita falha "would be clobbered" quando já existem pastas/cópias em ~/.config
  linkForce = rel: {
    source = link rel;
    force = true;
  };
in
{
  xdg.configFile = {
    "hypr" = linkForce "config/hypr";
    "kitty" = linkForce "config/kitty";
    "rofi" = linkForce "config/rofi";
    "gtk-3.0" = linkForce "config/gtk-3.0";
    "gtk-4.0" = linkForce "config/gtk-4.0";
    #    "environment.d" = linkForce "config/environment.d";
    "fastfetch" = linkForce "config/fastfetch";
    "Kvantum" = linkForce "config/Kvantum";
    "qt5ct" = linkForce "config/qt5ct";
    "qt6ct" = linkForce "config/qt6ct";
    "kde-material-you-colors" = linkForce "config/kde-material-you-colors";
    "xdg-desktop-portal" = linkForce "config/xdg-desktop-portal";
    "mpv" = linkForce "config/mpv";
    # Apenas settings + keybindings (resto de ~/.config/Cursor fica local: extensões, cache, etc.)
    "Cursor/User/settings.json" = linkForce "config/cursor/User/settings.json";
    "Cursor/User/keybindings.json" = linkForce "config/cursor/User/keybindings.json";
  };

  # 1. Cria o aplicativo fantasma no sistema
  xdg.desktopEntries."mpv-stremio" = {
    name = "MPV (Stremio Auto-Clean)";
    exec = "mpv-stremio-cleaner %U";
    terminal = false;
    categories = [ "AudioVideo" "Video" ];
    mimeType = [ "audio/x-mpegurl" "application/vnd.apple.mpegurl" "audio/mpegurl" ];
  };

  # Defaults de abertura: Cursor (texto), umpv (áudio/vídeo), imv-dir (imagens).
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      (lib.genAttrs [
        # Tipos que o vim.desktop / gvim.desktop declaram
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
        "text/markdown"
        "text/x-python"
        "text/x-script.python"
        "application/json"
        "text/x-lua"
        "text/css"
        "application/javascript"
        "text/javascript"
        "text/x-yaml"
        "application/x-yaml"
        "application/toml"
        "text/x-nix"
        "text/x-sh"
        "text/x-go"
        "text/x-rust"
        "text/x-ruby"
        "inode/x-empty"
      ] (_: [ "cursor.desktop" ]))
      // (lib.genAttrs [
        "application/ogg"
        "application/x-ogg"
        "application/mxf"
        "application/sdp"
        "application/smil"
        "application/x-smil"
        "application/streamingmedia"
        "application/x-streamingmedia"
        "application/vnd.rn-realmedia"
        "application/vnd.rn-realmedia-vbr"
        "audio/aac"
        "audio/x-aac"
        "audio/vnd.dolby.heaac.1"
        "audio/vnd.dolby.heaac.2"
        "audio/aiff"
        "audio/x-aiff"
        "audio/m4a"
        "audio/x-m4a"
        "application/x-extension-m4a"
        "audio/mp1"
        "audio/x-mp1"
        "audio/mp2"
        "audio/x-mp2"
        "audio/mp3"
        "audio/x-mp3"
        "audio/mpeg"
        "audio/mpeg2"
        "audio/mpeg3"
        "audio/mpegurl"
        "audio/x-mpegurl"
        "audio/mpg"
        "audio/x-mpg"
        "audio/rn-mpeg"
        "audio/musepack"
        "audio/x-musepack"
        "audio/ogg"
        "audio/scpls"
        "audio/x-scpls"
        "audio/vnd.rn-realaudio"
        "audio/wav"
        "audio/x-pn-wav"
        "audio/x-pn-windows-pcm"
        "audio/x-realaudio"
        "audio/x-pn-realaudio"
        "audio/x-ms-wma"
        "audio/x-pls"
        "audio/x-wav"
        "video/mpeg"
        "video/x-mpeg2"
        "video/x-mpeg3"
        "video/mp4v-es"
        "video/x-m4v"
        "video/mp4"
        "application/x-extension-mp4"
        "video/divx"
        "video/vnd.divx"
        "video/msvideo"
        "video/x-msvideo"
        "video/ogg"
        "video/quicktime"
        "video/vnd.rn-realvideo"
        "video/x-ms-afs"
        "video/x-ms-asf"
        "audio/x-ms-asf"
        "application/vnd.ms-asf"
        "video/x-ms-wmv"
        "video/x-ms-wmx"
        "video/x-ms-wvxvideo"
        "video/x-avi"
        "video/avi"
        "video/x-flic"
        "video/fli"
        "video/x-flc"
        "video/flv"
        "video/x-flv"
        "video/x-theora"
        "video/x-theora+ogg"
        "video/x-matroska"
        "video/mkv"
        "audio/x-matroska"
        "application/x-matroska"
        "video/webm"
        "audio/webm"
        "audio/vorbis"
        "audio/x-vorbis"
        "audio/x-vorbis+ogg"
        "video/x-ogm"
        "video/x-ogm+ogg"
        "application/x-ogm"
        "application/x-ogm-audio"
        "application/x-ogm-video"
        "application/x-shorten"
        "audio/x-shorten"
        "audio/x-ape"
        "audio/x-wavpack"
        "audio/x-tta"
        "audio/AMR"
        "audio/ac3"
        "audio/eac3"
        "audio/amr-wb"
        "video/mp2t"
        "audio/flac"
        "audio/mp4"
        "application/x-mpegurl"
        "video/vnd.mpegurl"
        "application/vnd.apple.mpegurl"
        "audio/x-pn-au"
        "video/3gp"
        "video/3gpp"
        "video/3gpp2"
        "audio/3gpp"
        "audio/3gpp2"
        "video/dv"
        "audio/dv"
        "audio/opus"
        "audio/vnd.dts"
        "audio/vnd.dts.hd"
        "audio/x-adpcm"
        "application/x-cue"
        "audio/m3u"
        "audio/vnd.wave"
        "video/vnd.avi"
      ] (_: [ "umpv.desktop" ]))
      // (lib.genAttrs [
        "image/x-farbfeld"
        "image/tiff"
        "image/tiff-fx"
        "image/png"
        "image/x-png"
        "image/jpeg"
        "image/jpg"
        "image/pjpeg"
        "image/svg+xml"
        "image/gif"
        "image/bmp"
        "image/x-bmp"
        "image/heif"
        "image/avif"
        "image/jxl"
        "image/webp"
        "image/qoi"
      ] (_: [ "imv-dir.desktop" ]));
  };
}
