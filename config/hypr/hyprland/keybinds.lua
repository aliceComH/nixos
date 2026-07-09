-- Rofi
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("SUPER + Z", hl.dsp.exec_cmd("sh ~/.config/hypr/hyprland/scripts/rofimoji.sh"))

-- Reload hyprland
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("hyprctl reload"))

hl.bind("SUPER + F11", hl.dsp.exec_cmd("bash /etc/nixos/config/hypr/hyprland/scripts/toggle-blank-oled.sh"))
hl.bind("SUPER + F12", hl.dsp.exec_cmd("bash /etc/nixos/config/hypr/hyprland/scripts/toggle-blank-tv.sh"))

-- Audio control
hl.bind("F11", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh down"), { repeating = true })
hl.bind("F12", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh up"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh down cloud3"), { repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh up cloud3"), { repeating = true })

-- OCR
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/ocr.sh"), { description = "Character recognition" })

-- Screenshot
hl.bind("PRINT", hl.dsp.exec_cmd("mkdir -p $(xdg-user-dir PICTURES)/Screenshots && grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"), { locked = true, description = "Screenshot >> clipboard & save" })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"), { description = "Screen snip" })

-- programs
hl.bind("ALT + F1", hl.dsp.exec_cmd("kitty --class btop --title btop -e btop"))
hl.bind("ALT + F2", hl.dsp.exec_cmd("kitty s-tui"))
hl.bind("ALT + F3", hl.dsp.exec_cmd("lact"))
hl.bind("SUPER + ALT + X", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind("ALT + ESCAPE", hl.dsp.window.close())
hl.bind("ALT + Q", hl.dsp.exec_cmd("kitty --title main"))
hl.bind("SUPER + dead_grave", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/switch-audio-sink.sh"))
hl.bind("SUPER + SHIFT + dead_grave", hl.dsp.exec_cmd("mirror-audio toggle"))
hl.bind("ALT + W", hl.dsp.exec_cmd("pavucontrol"))
hl.bind("ALT + E", hl.dsp.exec_cmd("kitty --class yazi --title yazi -e yazi"))
hl.bind("ALT + R", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind("ALT + C", hl.dsp.exec_cmd("antigravity-ide"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("gnome-calculator"))
hl.bind("ALT + 1", hl.dsp.exec_cmd("vesktop --enable-features=WebRTCPipeWireCapturer"))
hl.bind("ALT + 2", hl.dsp.exec_cmd("flatpak run com.meetfranz.Franz"))
hl.bind("ALT + 3", hl.dsp.exec_cmd("steam"))
hl.bind("ALT + 4", hl.dsp.exec_cmd("google-chrome-stable --app=\"https://web.stremio.com/\""))
hl.bind("ALT + 5", hl.dsp.exec_cmd("cd ~/Projetos/jarvis && nix-shell --run \"GTK_THEME=Adwaita:dark python jarvis.py\""))
hl.bind("ALT + 6", hl.dsp.exec_cmd("google-chrome-stable --app=\"https://music.youtube.com/\""))

-- Shutdown menu
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("kitty systemctl poweroff -i"))
hl.bind("CTRL + SHIFT + dead_grave", hl.dsp.exec_cmd("kitty reboot"))

-- Fullscreen
hl.bind("SUPER + F", hl.dsp.window.fullscreen())

-- Floating window
hl.bind("SUPER + SPACE", hl.dsp.window.float({ action = "toggle" }))

-- Move windows between workspaces
hl.bind("ALT + A", hl.dsp.window.move({ workspace = "1", follow = false }))
hl.bind("ALT + S", hl.dsp.window.move({ workspace = "2", follow = false }))
hl.bind("ALT + D", hl.dsp.window.move({ workspace = "3", follow = false }))
hl.bind("ALT + F", hl.dsp.window.move({ workspace = "4", follow = false }))
hl.bind("ALT + G", hl.dsp.window.move({ workspace = "6", follow = false }))
hl.bind("ALT + SHIFT + Q", hl.dsp.window.move({ workspace = "7", follow = false }))
hl.bind("ALT + SHIFT + W", hl.dsp.focus({ workspace = "7" }))

-- Navegação inteligente de workspaces
hl.bind("ALT + TAB", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/cycle_workspaces.sh next"))
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/cycle_workspaces.sh prev"))
hl.bind("ALT + dead_grave", hl.dsp.focus({ workspace = "emptynm" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- Workspace auxiliar (8) e gaming (5)
hl.bind("F6", hl.dsp.focus({ workspace = "5" }))
hl.bind("ALT + F6", hl.dsp.window.move({ workspace = "5", follow = false }))

hl.bind("F8", function()
    hl.dispatch(hl.dsp.focus({ workspace = "8" }))
    hl.dispatch(hl.dsp.cursor.move({ x = 26580, y = 540 }))
end)
hl.bind("ALT + F8", hl.dsp.window.move({ workspace = "8", follow = false }))

hl.bind("F9", hl.dsp.focus({ workspace = "9" }))
hl.bind("ALT + F9", hl.dsp.window.move({ workspace = "9", follow = false }))

-- LLM (Ollama + Open WebUI)
hl.bind("SUPER + SHIFT + F1", hl.dsp.exec_cmd("llm-start"), { description = "LLM ligar" })
hl.bind("SUPER + SHIFT + F2", hl.dsp.exec_cmd("llm-stop"), { description = "LLM desligar" })

hl.define_submap("gaming", function() -- GAMING
    hl.bind("F6", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/workspace_previous_filtered.sh"))
    hl.bind("ALT + F6", hl.dsp.window.move({ workspace = "2", follow = false }))

    hl.bind("F8", function()
        hl.dispatch(hl.dsp.focus({ workspace = "8" }))
        hl.dispatch(hl.dsp.cursor.move({ x = 26580, y = 540 }))
    end)
    hl.bind("ALT + F8", hl.dsp.window.move({ workspace = "8", follow = false }))

    hl.bind("F9", hl.dsp.focus({ workspace = "9" }))
    hl.bind("ALT + F9", hl.dsp.window.move({ workspace = "9", follow = false }))

    hl.bind("ALT + ESCAPE", hl.dsp.window.close())
    hl.bind("SUPER + ALT + X", hl.dsp.exec_cmd("hyprctl kill"))
    hl.bind("SUPER + F", hl.dsp.window.fullscreen())
    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

    hl.bind("F11", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh down"), { repeating = true })
    hl.bind("F12", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh up"), { repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh down cloud3"), { repeating = true })
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh up cloud3"), { repeating = true })
    hl.bind("SUPER + dead_grave", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/switch-audio-sink.sh"))
    hl.bind("SUPER + SHIFT + dead_grave", hl.dsp.exec_cmd("mirror-audio toggle"))

    hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("hyprctl reload"))

    hl.bind("SUPER + F11", hl.dsp.exec_cmd("bash /etc/nixos/config/hypr/hyprland/scripts/toggle-blank-oled.sh"))
    hl.bind("SUPER + F12", hl.dsp.exec_cmd("bash /etc/nixos/config/hypr/hyprland/scripts/toggle-blank-tv.sh"))
    hl.bind("PRINT", hl.dsp.exec_cmd("mkdir -p $(xdg-user-dir PICTURES)/Screenshots && grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"), { locked = true, description = "Screenshot >> clipboard & save" })
    hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"), { description = "Screen snip" })
end)

hl.define_submap("osu", function() -- OSU
    hl.bind("F6", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/workspace_previous_filtered.sh"))
    hl.bind("ALT + F6", hl.dsp.window.move({ workspace = "2", follow = false }))

    hl.bind("F8", function()
        hl.dispatch(hl.dsp.focus({ workspace = "8" }))
        hl.dispatch(hl.dsp.cursor.move({ x = 26580, y = 540 }))
    end)
    hl.bind("ALT + F8", hl.dsp.window.move({ workspace = "8", follow = false }))

    hl.bind("F9", hl.dsp.focus({ workspace = "9" }))
    hl.bind("ALT + F9", hl.dsp.window.move({ workspace = "9", follow = false }))

    hl.bind("ALT + ESCAPE", hl.dsp.window.close())
    hl.bind("SUPER + F", hl.dsp.window.fullscreen())
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

    hl.bind("F11", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh down"), { repeating = true })
    hl.bind("F12", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh up"), { repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh down cloud3"), { repeating = true })
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh up cloud3"), { repeating = true })
    hl.bind("SUPER + dead_grave", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/switch-audio-sink.sh"))
    hl.bind("SUPER + SHIFT + dead_grave", hl.dsp.exec_cmd("mirror-audio toggle"))

    hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("hyprctl reload"))

    hl.bind("mouse_up", hl.dsp.exec_cmd("true"))
    hl.bind("mouse_down", hl.dsp.exec_cmd("true"))
    hl.bind("ALT + mouse_up", hl.dsp.exec_cmd("true"))
    hl.bind("ALT + mouse_down", hl.dsp.exec_cmd("true"))
    hl.bind("SUPER + mouse_up", hl.dsp.exec_cmd("true"))
    hl.bind("SUPER + mouse_down", hl.dsp.exec_cmd("true"))
    hl.bind("ALT + SUPER + mouse_up", hl.dsp.exec_cmd("true"))
    hl.bind("ALT + SUPER + mouse_down", hl.dsp.exec_cmd("true"))
    hl.bind("MOD5 + mouse_up", hl.dsp.exec_cmd("true"))
    hl.bind("MOD5 + mouse_down", hl.dsp.exec_cmd("true"))
    -- hl.bind("Control_R + mouse_up", hl.dsp.exec_cmd("true"))
    -- hl.bind("Control_R + mouse_down", hl.dsp.exec_cmd("true"))
    -- hl.bind("MOD5 + Control_R + mouse_up", hl.dsp.exec_cmd("true"))
    -- hl.bind("MOD5 + Control_R + mouse_down", hl.dsp.exec_cmd("true"))

    hl.bind("SUPER + F11", hl.dsp.exec_cmd("bash /etc/nixos/config/hypr/hyprland/scripts/toggle-blank-oled.sh"))
    hl.bind("SUPER + F12", hl.dsp.exec_cmd("bash /etc/nixos/config/hypr/hyprland/scripts/toggle-blank-tv.sh"))
    hl.bind("PRINT", hl.dsp.exec_cmd("mkdir -p $(xdg-user-dir PICTURES)/Screenshots && grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"), { locked = true, description = "Screenshot >> clipboard & save" })
    hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"), { description = "Screen snip" })
end)

hl.define_submap("auxiliar", function() -- DISCORD
    hl.bind("F6", function()
        hl.dispatch(hl.dsp.focus({ workspace = "5" }))
        hl.dispatch(hl.dsp.cursor.move({ x = 1280, y = 720 }))
    end)
    hl.bind("ALT + F6", hl.dsp.window.move({ workspace = "5", follow = false }))

    hl.bind("F8", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/workspace_previous_filtered.sh && hyprctl dispatch \"hl.dsp.cursor.move({ x = 1280, y = 720 })\""))

    hl.bind("F9", function()
        hl.dispatch(hl.dsp.focus({ workspace = "9" }))
        hl.dispatch(hl.dsp.cursor.move({ x = 1280, y = 720 }))
    end)
    hl.bind("ALT + F9", hl.dsp.window.move({ workspace = "9", follow = false }))

    hl.bind("SUPER + TAB", hl.dsp.exec_cmd("rofi -show drun"))
    hl.bind("SUPER + Z", hl.dsp.exec_cmd("sh ~/.config/hypr/hyprland/scripts/rofimoji.sh"))

    hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("hyprctl reload"))
    hl.bind("SUPER + F11", hl.dsp.exec_cmd("bash /etc/nixos/config/hypr/hyprland/scripts/toggle-blank-oled.sh"))
    hl.bind("SUPER + F12", hl.dsp.exec_cmd("bash /etc/nixos/config/hypr/hyprland/scripts/toggle-blank-tv.sh"))

    hl.bind("F11", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh down"), { repeating = true })
    hl.bind("F12", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh up"), { repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh down cloud3"), { repeating = true })
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh up cloud3"), { repeating = true })

    hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/ocr.sh"), { description = "Character recognition" })
    hl.bind("PRINT", hl.dsp.exec_cmd("mkdir -p $(xdg-user-dir PICTURES)/Screenshots && grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"), { locked = true })
    hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"), { description = "Screen snip" })

    hl.bind("ALT + F1", hl.dsp.exec_cmd("kitty --class btop --title btop -e btop"))
    hl.bind("ALT + F2", hl.dsp.exec_cmd("kitty s-tui"))
    hl.bind("ALT + F3", hl.dsp.exec_cmd("lact"))
    hl.bind("SUPER + ALT + X", hl.dsp.exec_cmd("hyprctl kill"))
    hl.bind("ALT + ESCAPE", hl.dsp.window.close())
    hl.bind("ALT + Q", hl.dsp.exec_cmd("kitty --title main"))
    hl.bind("SUPER + dead_grave", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/switch-audio-sink.sh"))
    hl.bind("SUPER + SHIFT + dead_grave", hl.dsp.exec_cmd("mirror-audio toggle"))
    hl.bind("ALT + W", hl.dsp.exec_cmd("pavucontrol"))
    hl.bind("ALT + E", hl.dsp.exec_cmd("kitty --class yazi --title yazi -e yazi"))
    hl.bind("ALT + R", hl.dsp.exec_cmd("google-chrome-stable"))
    hl.bind("ALT + C", hl.dsp.exec_cmd("antigravity-ide"))
    hl.bind("SUPER + C", hl.dsp.exec_cmd("gnome-calculator"))
    hl.bind("ALT + 1", hl.dsp.exec_cmd("vesktop --enable-features=WebRTCPipeWireCapturer"))
    hl.bind("ALT + 2", hl.dsp.exec_cmd("flatpak run com.meetfranz.Franz"))
    hl.bind("ALT + 3", hl.dsp.exec_cmd("steam"))
    hl.bind("ALT + 4", hl.dsp.exec_cmd("google-chrome-stable --app=\"https://web.stremio.com/\""))
    hl.bind("ALT + 5", hl.dsp.exec_cmd("cd ~/Projetos/jarvis && nix-shell --run \"GTK_THEME=Adwaita:dark python jarvis.py\""))
    hl.bind("ALT + 6", hl.dsp.exec_cmd("google-chrome-stable --app=\"https://music.youtube.com/\""))

    hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("kitty systemctl poweroff -i"))
    hl.bind("CTRL + SHIFT + dead_grave", hl.dsp.exec_cmd("kitty reboot"))

    hl.bind("SUPER + F", hl.dsp.window.fullscreen())
    hl.bind("SUPER + SPACE", hl.dsp.window.float({ action = "toggle" }))

    hl.bind("ALT + A", hl.dsp.window.move({ workspace = "1", follow = false }))
    hl.bind("ALT + S", hl.dsp.window.move({ workspace = "2", follow = false }))
    hl.bind("ALT + D", hl.dsp.window.move({ workspace = "3", follow = false }))
    hl.bind("ALT + F", hl.dsp.window.move({ workspace = "4", follow = false }))

    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

    hl.bind("SUPER + SHIFT + F1", hl.dsp.exec_cmd("llm-start"), { description = "LLM ligar" })
    hl.bind("SUPER + SHIFT + F2", hl.dsp.exec_cmd("llm-stop"), { description = "LLM desligar" })
end)

hl.define_submap("whatsapp", function() -- WHATSAPP
    hl.bind("F6", hl.dsp.focus({ workspace = "5" }))
    hl.bind("ALT + F6", hl.dsp.window.move({ workspace = "5", follow = false }))

    hl.bind("F8", function()
        hl.dispatch(hl.dsp.focus({ workspace = "8" }))
        hl.dispatch(hl.dsp.cursor.move({ x = 26580, y = 540 }))
    end)
    hl.bind("ALT + F8", hl.dsp.window.move({ workspace = "8", follow = false }))

    hl.bind("F9", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/workspace_previous_filtered.sh"))

    hl.bind("SUPER + TAB", hl.dsp.exec_cmd("rofi -show drun"))
    hl.bind("SUPER + Z", hl.dsp.exec_cmd("sh ~/.config/hypr/hyprland/scripts/rofimoji.sh"))

    hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("hyprctl reload"))
    hl.bind("SUPER + F11", hl.dsp.exec_cmd("bash /etc/nixos/config/hypr/hyprland/scripts/toggle-blank-oled.sh"))
    hl.bind("SUPER + F12", hl.dsp.exec_cmd("bash /etc/nixos/config/hypr/hyprland/scripts/toggle-blank-tv.sh"))

    hl.bind("F11", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh down"), { repeating = true })
    hl.bind("F12", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh up"), { repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh down cloud3"), { repeating = true })
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/volume-control.sh up cloud3"), { repeating = true })

    hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/ocr.sh"), { description = "Character recognition" })
    hl.bind("PRINT", hl.dsp.exec_cmd("mkdir -p $(xdg-user-dir PICTURES)/Screenshots && grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"), { locked = true })
    hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"), { description = "Screen snip" })

    hl.bind("ALT + F1", hl.dsp.exec_cmd("kitty --class btop --title btop -e btop"))
    hl.bind("ALT + F2", hl.dsp.exec_cmd("kitty s-tui"))
    hl.bind("ALT + F3", hl.dsp.exec_cmd("lact"))
    hl.bind("SUPER + ALT + X", hl.dsp.exec_cmd("hyprctl kill"))
    hl.bind("ALT + ESCAPE", hl.dsp.window.close())
    hl.bind("ALT + Q", hl.dsp.exec_cmd("kitty --title main"))
    hl.bind("SUPER + dead_grave", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/switch-audio-sink.sh"))
    hl.bind("SUPER + SHIFT + dead_grave", hl.dsp.exec_cmd("mirror-audio toggle"))
    hl.bind("ALT + W", hl.dsp.exec_cmd("pavucontrol"))
    hl.bind("ALT + E", hl.dsp.exec_cmd("kitty --class yazi --title yazi -e yazi"))
    hl.bind("ALT + R", hl.dsp.exec_cmd("google-chrome-stable"))
    hl.bind("ALT + C", hl.dsp.exec_cmd("antigravity-ide"))
    hl.bind("SUPER + C", hl.dsp.exec_cmd("gnome-calculator"))
    hl.bind("ALT + 1", hl.dsp.exec_cmd("vesktop --enable-features=WebRTCPipeWireCapturer"))
    hl.bind("ALT + 2", hl.dsp.exec_cmd("flatpak run com.meetfranz.Franz"))
    hl.bind("ALT + 3", hl.dsp.exec_cmd("steam"))
    hl.bind("ALT + 4", hl.dsp.exec_cmd("google-chrome-stable --app=\"https://web.stremio.com/\""))
    hl.bind("ALT + 5", hl.dsp.exec_cmd("cd ~/Projetos/jarvis && nix-shell --run \"GTK_THEME=Adwaita:dark python jarvis.py\""))
    hl.bind("ALT + 6", hl.dsp.exec_cmd("google-chrome-stable --app=\"https://music.youtube.com/\""))

    hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("kitty systemctl poweroff -i"))
    hl.bind("CTRL + SHIFT + dead_grave", hl.dsp.exec_cmd("kitty reboot"))

    hl.bind("SUPER + F", hl.dsp.window.fullscreen())
    hl.bind("SUPER + SPACE", hl.dsp.window.float({ action = "toggle" }))

    hl.bind("ALT + A", hl.dsp.window.move({ workspace = "1", follow = false }))
    hl.bind("ALT + S", hl.dsp.window.move({ workspace = "2", follow = false }))
    hl.bind("ALT + D", hl.dsp.window.move({ workspace = "3", follow = false }))
    hl.bind("ALT + F", hl.dsp.window.move({ workspace = "4", follow = false }))

    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

    -- Navegação inteligente de workspaces
    hl.bind("ALT + TAB", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/cycle_workspaces.sh next"))
    hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("bash ~/.config/hypr/hyprland/scripts/cycle_workspaces.sh prev"))
    hl.bind("ALT + dead_grave", hl.dsp.focus({ workspace = "emptynm" }))

    hl.bind("SUPER + SHIFT + F1", hl.dsp.exec_cmd("llm-start"), { description = "LLM ligar" })
    hl.bind("SUPER + SHIFT + F2", hl.dsp.exec_cmd("llm-stop"), { description = "LLM desligar" })
end)
