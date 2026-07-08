-- Yazi init.lua — carrega plugins e configurações extras

-- relative-motions: permite mover N linhas (5j, 10k estilo vim)
require("relative-motions"):setup({
  show_numbers = "relative",   -- mostra números relativos na barra lateral
  show_motion  = true,         -- mostra o motion no status bar
})

-- require("git"):setup()

-- starship: usa o prompt starship no header do yazi
-- (requer starship instalado — já temos em config/starship.toml)
require("starship"):setup()
