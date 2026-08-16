--  ######## Workspace rules — Workspace 9 (PWAs) ########
--
--  Casa pelo WM_CLASS FFPWA-<ulid> (estável). `title` no Hyprland é o
--  initialTitle: o WhatsApp vira "Mozilla Firefox" depois do load e o
--  YouTube Music nasceu com initialTitle truncado (`"YouTube`).

hl.window_rule({
    match = { class = "^FFPWA-01M05T5S6CXP43B4RVDNCPX6XC$" },
    workspace = "9 silent",
    idle_inhibit = "focus",
})

hl.window_rule({
    match = { class = "^FFPWA-01M05T56XMVRWSSVMYPTX6VM98$" },
    workspace = "9 silent",
    idle_inhibit = "focus",
})

--  Fallback se o site for reinstalado (ulid novo).
hl.window_rule({
    match = {
        class = "^FFPWA-.+$",
        initial_title = ".*[Ww]hats[Aa]pp.*",
    },
    workspace = "9 silent",
    idle_inhibit = "focus",
})
hl.window_rule({
    match = {
        class = "^FFPWA-.+$",
        initial_title = ".*[Yy]ou[Tt]ube.*",
    },
    workspace = "9 silent",
    idle_inhibit = "focus",
})
