--  Chrome + HTML5 fullscreen em tiling: maximize fantasma ao sair do F do vídeo.
--  1) Regra oficial do exemplo Hyprland 0.54 (named rule) — mais fiável que one-liner.
--  2) `sync_fullscreen` é nativo do Hyprland 0.55; não precisa mais do patch
--     PR #13790 usado nas versões anteriores.

hl.window_rule({
  name = "chrome-suppress-client-maximize",
  match = { class = "^(google-chrome|Google-chrome)$" },
  suppress_event = "maximize"
})

hl.window_rule({
  name = "chrome-sync-fullscreen",
  match = { class = "^(google-chrome|Google-chrome)$" },
  sync_fullscreen = true
})
