--  ######## Workspace rules — Workspace 7 (Media) ########

--  Firefox abre silenciosamente no workspace 7 (dedicado a consumo de mídia).
--  O conteúdo é capturado via OBS e transmitido ao MPV com interpolação.
hl.window_rule({
    match = {
        class = "^(firefox)$",
    },
    workspace = "7 silent",
    immediate = false,
    idle_inhibit = "focus",
})
