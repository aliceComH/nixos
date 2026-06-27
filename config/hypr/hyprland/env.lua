-- ######### Input method ##########
-- See https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
-- hl.env("QT_IM_MODULE", "fcitx")
-- hl.env("XMODIFIERS", "@im=fcitx")
-- hl.env("SDL_IM_MODULE", "fcitx")
-- hl.env("GLFW_IM_MODULE", "ibus")
-- hl.env("INPUT_METHOD", "fcitx")

-- ############ Wayland #############
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ############ Themes #############
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- ######## Wayland #########
-- Tearing
hl.env("WLR_DRM_NO_ATOMIC", "0")
hl.env("WLR_NO_HARDWARE_CURSORS", "0")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("GDK_BACKEND", "wayland,x11")

-- ######## Virtual envrionment #########
-- hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", "~/.local/state/quickshell/.venv")

-- ######## Terminal application #########
hl.env("TERMINAL", "kitty -1")

hl.env("QT_QPA_PLATFORMTHEME", "gtk4")

-- hl.env("XCURSOR_THEME", "Breeze_Snow")
hl.env("XCURSOR_THEME", "Bibata-Original-Ice")
hl.env("XCURSOR_SIZE", "32")
