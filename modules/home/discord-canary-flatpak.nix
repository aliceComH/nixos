# Discord Canary (Flatpak): flags Chromium lidas por discord-canary.sh via
# XDG_CONFIG_HOME → ~/.var/app/com.discordapp.DiscordCanary/config/discord-flags.conf
#
# No Wayland, vídeo e áudio do screen share passam pelo PipeWire + xdg-desktop-portal
# (o Hyprland usa xdg-desktop-portal-hyprland). O nome do switch vem de
# chrome/common/chrome_switches.cc (kSystemAudioCaptureDefaultChecked).
{ ... }:

{
  home.file.".var/app/com.discordapp.DiscordCanary/config/discord-flags.conf" = {
    text = ''
      # Marcar por defeito «partilhar áudio do sistema» no selector de captura (Chromium).
      --system-audio-capture-default_checked
      # Garantir captura WebRTC via PipeWire (útil se o build não activar por defeito).
      --enable-features=WebRTCPipeWireCapturer
    '';
  };
}
