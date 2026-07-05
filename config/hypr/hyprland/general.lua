hl.monitor({
  output = "DP-3",
  mode = "2560x1440@280",
  position = "0x0",
  scale = 1,
  vrr = 0,
})

hl.monitor({
  output = "HDMI-A-1",
  mode = "3920x2160@120",
  position = "25600x0",
  scale = 1.5,
  vrr = 0,
})

for _, ws in ipairs({"1", "2", "3", "4", "5", "6", "7", "9", "10"}) do
    hl.workspace_rule({ 
        workspace = ws,
        monitor = "DP-3",
        no_rounding = true,
        decorate = false,
        gaps_in = 0,
        gaps_out = 0,
        no_border = true,
    })
end

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        gaps_workspaces = 0,
        border_size = 0,
        ["col.active_border"] = "rgba(0DB7D4FF)",
        ["col.inactive_border"] = "rgba(31313600)",
        resize_on_border = false,
        no_focus_fallback = true,
        allow_tearing = true,
        snap = {
            enabled = true,
            window_gap = 0,
            monitor_gap = 0,
            respect_gaps = true
        }
    },
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false,
        precise_mouse_move = true
    },
    decoration = {
        rounding = 0,
        blur = {
            enabled = true,
            xray = true,
            special = false,
            new_optimizations = true,
            size = 8,
            passes = 4,
            brightness = 1,
            noise = 0.04,
            contrast = 1,
            popups = true,
            popups_ignorealpha = 0.6,
            input_methods = true,
            input_methods_ignorealpha = 0.8
        },
        shadow = {
            enabled = true,
--            ignore_window = true,
            range = 30,
            offset = {0, 2},
            render_power = 4,
            color = "rgba(00000010)"
        },
        dim_inactive = true,
        dim_strength = 0.025,
        dim_special = 0.07
    },
    animations = {
        enabled = true
    },
    input = {
        kb_layout = "us",
        kb_variant = "intl",
        kb_model = "pc105",
        kb_options = "",
        kb_rules = "",
        repeat_rate = 50,
        repeat_delay = 300,
        numlock_by_default = true,
        left_handed = false,
        float_switch_override_focus = 1,
        follow_mouse = 1,
        mouse_refocus = true,
        sensitivity = 0
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
  --      vfr = 0,
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        swallow_regex = "(foot|kitty|allacritty|Alacritty|mpv)",
        allow_session_lock_restore = true,
        session_lock_xray = true,
        initial_workspace_tracking = false,
        focus_on_activate = false,
        middle_click_paste = true
    },
    render = {
        direct_scanout = 0
    },
    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true,
        drag_threshold = 5
    },
    cursor = {
        zoom_factor = 1,
        zoom_rigid = false,
        hotspot_padding = 1,
        sync_gsettings_theme = true,
        no_hardware_cursors = 0,
        enable_hyprcursor = true,
        warp_on_change_workspace = 0,
        no_warps = true
    }
})

-- Curves (0.55 API: hl.curve)
hl.curve("fastDecel", { type = "bezier", points = { {0, 1}, {0, 1} } })
hl.curve("direct",    { type = "bezier", points = { {0.2, 0}, {0, 1} } })
hl.curve("liner",     { type = "bezier", points = { {1, 1}, {1, 1} } })

-- Animations (0.55 API: hl.animation)
hl.animation({ leaf = "windows",       enabled = true, speed = 2,    bezier = "fastDecel", style = "slide" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 1.8,  bezier = "fastDecel", style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.5,  bezier = "direct",    style = "slide" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 2,    bezier = "fastDecel", style = "slide" })
hl.animation({ leaf = "border",        enabled = true, speed = 1,    bezier = "liner" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 20,   bezier = "liner",     style = "loop" })
hl.animation({ leaf = "fade",          enabled = true, speed = 2,    bezier = "default" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 0.5,  bezier = "fastDecel", style = "slide" })
