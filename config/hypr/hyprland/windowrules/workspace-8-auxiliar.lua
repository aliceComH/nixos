--  ######## Workspace rules — Workspace 8 (Auxiliar) ########

--  Vesktop
hl.window_rule({
    match = {
        class = "^(vesktop)$",
    },
    workspace = "8 silent",
    immediate = false,
    idle_inhibit = "focus",
})

--  MPV
hl.window_rule({
    match = {
        class = "^(mpv)$",
    },
    workspace = "8",
    immediate = false,
    idle_inhibit = "focus",
})
