--  ######## Workspace rules — Workspace 8 (Auxiliar) ########

--  Aplicações que abrem silenciosamente no auxiliar
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-1", no_rounding = true, decorate = false, gaps_in = 0, gaps_out = 0, no_border = true })
hl.window_rule({ match = { class = "^(vesktop)$" }, workspace = "8 silent" })
