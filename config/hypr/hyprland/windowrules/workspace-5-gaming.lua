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

--  Prism Launcher (Minecraft Java): todas as janelas do launcher flutuando no 5.
--  Sem "silent": o ALT + M leva junto para o workspace 5.
hl.window_rule({
    match = {
        class = "^(org\\.prismlauncher\\.PrismLauncher)$",
    },
    workspace = "5",
    float = true,
    center = true,
})

--  Minecraft Java (XWayland/GLFW): a class vem com a versão, "Minecraft* 1.21.1"
--  (o * aparece quando há mods). Fullscreen real (modo 2) para direct scanout
--  (ligado pelo gaming_monitor.sh no workspace 5); content "game" + immediate.
hl.window_rule({
    match = {
        class = "^(Minecraft\\*? [0-9].*)$",
    },
    workspace = "5 silent",
    fullscreen = true,
    content = "game",
    immediate = true,
    no_blur = true,
    no_shadow = true,
    idle_inhibit = "fullscreen",
})
