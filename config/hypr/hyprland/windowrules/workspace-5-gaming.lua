--  ######## Workspace rules — Workspace 5 (Gaming) ########

--  Performance rules for osu! (seguindo o seu padrão de games)
hl.window_rule({
    match = {
        class = "^(osu!)$",
    },
    workspace = "5 silent",
    float = true,
    no_shadow = true,
    immediate = true,
})

--  Direct scanout-friendly rules (removes extra effects)
hl.window_rule({
    match = {
        class = "^steam_app_.*$",
    },
    workspace = "5 silent",
    no_shadow = true,
    float = true,
})
hl.window_rule({
    match = {
        class = "^dota2*$",
    },
    workspace = "5 silent",
    no_shadow = true,
    float = true,
})

--  Minecraft Bedrock (BedrockOnLinux / WineGDK)
hl.window_rule({
    match = {
        class = "^(bedrock-on-linux)$",
    },
    workspace = "5 silent",
    no_shadow = true,
})
hl.window_rule({
    match = {
        class = "^(Minecraft\\.Windows\\.exe)$",
    },
    workspace = "5 silent",
    -- Tearing (immediate) só vale em fullscreen no Hyprland 0.55.
    fullscreen = true,
    immediate = true,
    no_blur = true,
    no_shadow = true,
})

--  Regra específica para o Gamescope
hl.window_rule({
    match = {
        class = "^(gamescope)$",
    },
    workspace = "5 silent",
    immediate = true,
    no_blur = true,
    float = true,
})
