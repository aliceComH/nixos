--  ######## Window rules — General ########

--  Uncomment to apply global transparency to all windows:
--  windowrulev2 = opacity 0.89 override 0.89 override, class:.*

--  Disable blur for xwayland context menus
hl.window_rule({ match = { class = "^()$", title = "^()$" }, no_blur = true })
--  windowrulev2 = noblur, xwayland:1
hl.window_rule({ match = { fullscreen = true }, no_blur = true })
hl.window_rule({ match = { fullscreen = true }, opacity = "1.0 1.0" })
--  windowrule = opacity 0.90 0.90, match:class ^(google-chrome)$
--  windowrulev2 = opacity 0.80 0.80,class:^(google-chrome)$
hl.window_rule({ match = { class = "^(org.telegram.desktop)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(code)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(code-oss)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(code-url-handler)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(code-insiders-url-handler)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(qt5ct)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(qt6ct)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(org.kde.ark)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(Alacritty)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(kitty)$" }, opacity = "0.70 0.70" })
hl.window_rule({ match = { class = "^(yazi)$" }, opacity = "0.70 0.70" })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^([Ss]team)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(steamwebhelper)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(vesktop)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(WebCord)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(yad)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(polkit-gnome-authentication-agent-1)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.gtk)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.hyprland)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(org.gnome.Loupe)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(btop)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(evince)$" }, opacity = "0.90 0.90" })
