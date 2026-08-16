--  ######## Window rules — Floating / Tiling / PiP ########

--  Floating

hl.window_rule({ match = { class = "^(.piper-wrapped)$" }, float = true })
hl.window_rule({ match = { class = "^(.piper-wrapped)$" }, size = {"1067", "651"} })
hl.window_rule({ match = { class = "^(.piper-wrapped)$" }, center = true })
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, float = true })
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, size = {"440", "600"} })
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, move = {"280", "400"} })
hl.window_rule({ match = { class = "^(btop)$" }, float = true })
hl.window_rule({ match = { class = "^(btop)$" }, size = {"1152", "864"} })
hl.window_rule({ match = { class = "^(btop)$" }, center = true })
hl.window_rule({ match = { title = "^(Open File)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Open File)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Select a File)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Select a File)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, size = {"1536", "936"} })
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Save As)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Save As)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(.*)(wants to save)$" }, center = true })
hl.window_rule({ match = { title = "^(.*)(wants to save)$" }, float = true })
hl.window_rule({ match = { title = "^(.*)(wants to open)$" }, center = true })
hl.window_rule({ match = { title = "^(.*)(wants to open)$" }, float = true })
-- hl.window_rule({ match = { class = "^(blueberry\\.py)$" }, float = true })
hl.window_rule({ match = { class = "^(guifetch)$   # FlafyDev/guifetch" }, float = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, size = {"837", "747"} })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, size = {"837", "747"} })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, size = {"1152", "864"} })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, center = true })
hl.window_rule({ match = { class = ".*plasmawindowed.*" }, float = true })
hl.window_rule({ match = { class = "kcm_.*" }, float = true })
hl.window_rule({ match = { class = ".*bluedevilwizard" }, float = true })
hl.window_rule({ match = { title = ".*Welcome" }, float = true })
hl.window_rule({ match = { title = "^(illogical-impulse Settings)$" }, float = true })
--  windowrulev2 = float, title:.*Shell conflicts.*
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, float = true })
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, size = {"1536", "936"} })
hl.window_rule({ match = { class = "^(Zotero)$" }, float = true })
hl.window_rule({ match = { class = "^(Zotero)$" }, size = {"1152", "1152"} })
hl.window_rule({ match = { class = "^(imv)$" }, float = true })
hl.window_rule({ match = { class = "^(imv)$" }, size = {"2509", "1411"} })
hl.window_rule({ match = { class = "^(imv)$" }, center = true })
hl.window_rule({ match = { class = "^(imv-dir)$" }, float = true })
hl.window_rule({ match = { class = "^(imv-dir)$" }, size = {"2509", "1411"} })
hl.window_rule({ match = { class = "^(imv-dir)$" }, center = true })
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, float = true })
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, size = {"1152", "864"} })
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, center = true })
hl.window_rule({ match = { class = "^(jarvis.py)$" }, float = true })
hl.window_rule({ match = { class = "^(jarvis.py)$" }, size = {"400", "200"} })
hl.window_rule({ match = { class = "^(jarvis.py)$" }, center = true })
hl.window_rule({ match = { class = "^(thunar)$" }, float = true })
hl.window_rule({ match = { class = "^(thunar)$" }, size = {"1152", "864"} })
hl.window_rule({ match = { class = "^(thunar)$" }, center = true })
hl.window_rule({ match = { class = "^(Thunar)$" }, float = true })
hl.window_rule({ match = { class = "^(Thunar)$" }, size = {"1152", "864"} })
hl.window_rule({ match = { class = "^(Thunar)$" }, center = true })
hl.window_rule({ match = { class = "^(org.gnome.FileRoller)$" }, float = true })
hl.window_rule({ match = { class = "^(org.gnome.FileRoller)$" }, size = {"1152", "864"} })
hl.window_rule({ match = { class = "^(org.gnome.FileRoller)$" }, center = true })

--  Move
--  kde-material-you-colors spawns a window when changing dark/light theme. This is to make sure it doesn't interfere at all.
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, float = true })
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, move = {"999999", "999999"} })
--  stupid dolphin copy
hl.window_rule({ match = { title = "^(Copying — Dolphin)$" }, move = {"27", "53"} })

--  Tiling
-- hl.window_rule({ match = { class = "^dev\\.warp\\.Warp$" }, tile = true })

--  Picture-in-Picture
-- hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true })
-- hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, keep_aspect_ratio = true })
-- hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, move = {"1869", "1037"} })
-- hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, size = {"717", "403"} })
-- hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true })
-- hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, pin = true })

--  --- Tearing ---
--  windowrulev2 = immediate, title:.*\.exe
--  windowrulev2 = immediate, title:.*minecraft.*
--  windowrulev2 = immediate, class:^(steam_app).*

--  No shadow for tiled windows (matches windows that are not floating).
hl.window_rule({ match = { float = false }, no_shadow = true })

-- --- Monitor Blanking (Software via MPV) ---
-- Blank OLED
hl.window_rule({ match = { class = "^(blank-oled)$" }, float = true })
hl.window_rule({ match = { class = "^(blank-oled)$" }, monitor = "DP-3" })
hl.window_rule({ match = { class = "^(blank-oled)$" }, size = {"100%", "100%"} })
hl.window_rule({ match = { class = "^(blank-oled)$" }, center = true })
hl.window_rule({ match = { class = "^(blank-oled)$" }, border_size = 0 })
hl.window_rule({ match = { class = "^(blank-oled)$" }, no_focus = true })
hl.window_rule({ match = { class = "^(blank-oled)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^(blank-oled)$" }, pin = true })

-- Blank TV
hl.window_rule({ match = { class = "^(blank-tv)$" }, float = true })
hl.window_rule({ match = { class = "^(blank-tv)$" }, monitor = "HDMI-A-1" })
hl.window_rule({ match = { class = "^(blank-tv)$" }, size = {"100%", "100%"} })
hl.window_rule({ match = { class = "^(blank-tv)$" }, center = true })
hl.window_rule({ match = { class = "^(blank-tv)$" }, border_size = 0 })
hl.window_rule({ match = { class = "^(blank-tv)$" }, no_focus = true })
hl.window_rule({ match = { class = "^(blank-tv)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^(blank-tv)$" }, pin = true })
