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

--  Claudia (scanout + IP): HDMI, float, canto superior esquerdo (~3%)
hl.window_rule({
    match = {
        class = "^(claudia.py)$",
    },
    workspace = "8 silent",
    monitor = "HDMI-A-1",
    float = true,
    size = {"400", "200"},
    move = {"monitor_w * 0.03", "monitor_h * 0.03"},
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
