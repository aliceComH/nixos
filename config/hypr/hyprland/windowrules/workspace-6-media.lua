--  ######## Workspace rules — Workspace 6 (Media) ########

--  Workspace display settings: no rounding, gaps or borders
hl.config({ workspace = { "6, rounding:false, gapsin:0, gapsout:0, border:false" } })

--  Stremio → workspace 6
--  windowrule = workspace 6 silent, match:title ^(Stremio Web)$

--  MPV
-- hl.window_rule({ match = { class = "^(mpv)$" }, workspace = "6" })
-- hl.window_rule({ match = { class = "^(mpv)$" }, immediate = true })
-- hl.window_rule({ match = { class = "^(mpv)$" }, idle_inhibit = "focus" })
