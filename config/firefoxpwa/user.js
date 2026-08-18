// Prefs do perfil partilhado das PWAs (firefoxpwa não sobrescreve user.js).
user_pref("firefoxpwa.enableHidingIconBar", true);
user_pref("browser.tabs.inTitlebar", 0);
user_pref("browser.tabs.drawInTitlebar", false);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Cubeb mapeia HTML5 volume (loudness do YouTube) para a sink do PipeWire.
// Escala alta satura em 100% (0 dB); mute no player continua a funcionar.
// Manter em sincronia com programs.firefox.profiles.default.settings em firefox.nix.
user_pref("media.volume_scale", 3.0);
user_pref("media.default_volume", 1.0);
