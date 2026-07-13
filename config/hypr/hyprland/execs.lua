hl.on("hyprland.start", function()
    -- Bar, wallpaper
    -- hl.exec_cmd("~/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    -- hl.exec_cmd("qs -c $qsConfig &")

    -- Input method
    -- hl.exec_cmd("fcitx5")
    -- set_wallpaper.sh usa wallpapers/1.jpeg; gera hyprlang em ~/.local/state/.../hyprpaper.conf. Sleep: layer-shell no arranque.
    hl.exec_cmd("bash /home/alice/.config/hypr/hyprland/scripts/set_wallpaper.sh && sleep 0.75 && hyprpaper -c /home/alice/.local/state/nixos-wallpaper/hyprpaper.conf")
    
    -- Audio
    -- hl.exec_cmd("easyeffects --gapplication-service & disown")
    -- hl.exec_cmd("xwaylandvideobridge")

    -- Core components (authentication, lock screen, notification daemon)
    -- hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    -- hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1 || /usr/libexec/polkit-kde-authentication-agent-1  || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/libexec/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start nixos-fake-graphical-session.target")
    -- hyprpm reload removido: sem plugins evita o aviso "Outdated headers" no arranque.
    -- movido para systemd --user (Home Manager): hypr-gaming-monitor.service
    -- movido para systemd --user (Home Manager): hypr-opentabletdriver-autostart.service

    -- Clipboard: persistência e histórico (Wayland + PRIMARY selection)
    -- Sem watcher, o conteúdo pode "sumir" quando o app dono do clipboard fecha.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("wl-paste --primary --type text --watch cliphist store")

    -- Logitech Solaar: daemon que monitora devices Logitech via HID++ e reaaplica
    -- configs salvas (ex: fn-swap off no K400 Plus) automaticamente em reconexões.
    -- --window hide: roda sem GUI visível. 2>/dev/null: silencia warnings GTK/D-Bus.
    hl.exec_cmd("solaar --window hide 2>/dev/null")

    hl.exec_cmd("hyprctl setcursor Bibata-Original-Ice 32")
end)
