--  ######## Workspace rules — Workspace 4 (Social) ########

--  Force Youtube Music, Steam web helper and Steam to workspace 4 silently
hl.window_rule({ match = { class = "^(chrome-music.youtube.com__-Default)$" }, workspace = "4 silent" })
hl.window_rule({ match = { class = "^(steamwebhelper)$" }, workspace = "4 silent" })
hl.window_rule({ match = { class = "^([Ss]team)$" }, workspace = "4 silent" })
hl.window_rule({ match = { class = "^$", title = "^(Steam)$" }, workspace = "4 silent" })
hl.window_rule({ match = { class = "^(steam)$", title = "negative:^(Steam)$" }, float = true })
