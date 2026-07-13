--  ######## Workspace rules — Workspace 9 ########

hl.window_rule({ 
    match = { 
        class = "^(chrome-web.whatsapp.com__-Default)$"
    }, 
    workspace = "9 silent",
    immediate = false,
    idle_inhibit = "focus",
})
