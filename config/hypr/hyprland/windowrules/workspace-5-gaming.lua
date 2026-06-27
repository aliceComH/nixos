--  ######## Workspace rules — Workspace 5 (Gaming) ########

--  Workspace display settings: no rounding, gaps or borders
hl.config({ workspace = { "5, rounding:false, gapsin:0, gapsout:0, border:false" } })

--  (removed 0.54) layerrule = noanim,5  # per-workspace layer rules use match:namespace; adjust via hyprctl layers if needed
--  (removed 0.54) layerrule = ignorezero,5  # per-workspace layer rules use match:namespace; adjust via hyprctl layers if needed

--  Force all Steam games to workspace 5 silently (syntax 0.54+).

--  Performance rules for osu! (seguindo o seu padrão de games)
hl.window_rule({ match = { class = "^(osu!)$" }, float = true })
--  windowrule = fullscreen on, match:class ^(osu!)$
hl.window_rule({ match = { class = "^(osu!)$" }, no_shadow = true })
hl.window_rule({ match = { class = "^(osu!)$" }, immediate = true })

--  Make Steam games float
hl.window_rule({ match = { class = "^steam_app_.*$" }, float = true })
hl.window_rule({ match = { class = "^dota2*$" }, float = true })
--  windowrulev2 = contenttype:game, class:^steam_app_.*$

--  Force fullscreen
--  windowrule = fullscreen on, match:class ^steam_app_.*$
--  windowrulev2 = fullscreenstate:fullscreen, class:^steam_app_.*$
--  windowrule = fullscreen on, match:class ^dota2*$
--  windowrulev2 = fullscreenstate:fullscreen, class:^dota2*$

--  Direct scanout-friendly rules (removes extra effects)
hl.window_rule({ match = { class = "^steam_app_.*$" }, no_shadow = true })
hl.window_rule({ match = { class = "^dota2*$" }, no_shadow = true })
--  windowrulev2 = immediate, class:^steam_app_.*$

--  Set content type to "game" (may help with special behavior or direct scanout)
--  windowrulev2 = contenttype:game, class:^steam_app_.*$
--  windowrulev2 = contenttype:game, class:^dota2*$

--  Regra específica para o Gamescope
hl.window_rule({ match = { class = "^(gamescope)$" }, immediate = true })
hl.window_rule({ match = { class = "^(gamescope)$" }, workspace = "5 silent" })

--  Opcional: remover blur/gaps quando o gamescope estiver aberto para garantir performance
hl.window_rule({ match = { class = "^(gamescope)$" }, no_blur = true })
