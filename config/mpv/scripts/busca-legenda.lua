-- config/mpv/scripts/busca-legenda.lua

function busca_legenda()
    -- Tenta pegar o nome limpo que o Stremio envia no arquivo M3U
    local title = mp.get_property("media-title") or ""
    
    if title == "" then 
        title = mp.get_property("filename") 
    end

    -- Troca espaços por '+' para formatar o link de pesquisa
    local search_query = title:gsub(" ", "+")

    -- Monta a URL direta para o OpenSubtitles filtrando por PT-BR
    local url = "https://www.opensubtitles.org/pb/search/sublanguageid-pob/moviebytesize-all/moviename-" .. search_query

    mp.osd_message("Buscando legendas para: " .. title)
    
    -- Dispara o xdg-open para o Hyprland abrir a sua aba do navegador instantaneamente
    os.execute("xdg-open '" .. url .. "' &")
end

-- Mapeia o atalho Ctrl+F para disparar a função
mp.add_key_binding("ctrl+f", "busca_legenda", busca_legenda)