-- Espera 3 segundos antes de aplicar o perfil interp-vector
-- Isso dá tempo pro mpv "respirar" e evita crashes no primeiro frame com o VapourSynth em 120fps

mp.add_timeout(3.0, function()
    -- Verifica se tem vídeo (não queremos rodar interpolação em música/audio sem vídeo)
    local tracks = mp.get_property_native("track-list")
    local has_video = false
    
    if tracks then
        for _, track in ipairs(tracks) do
            if track.type == "video" and not track.albumart then
                has_video = true
                break
            end
        end
    end
    
    if has_video then
        mp.commandv("apply-profile", "interp-vector")
        mp.osd_message("Interpolação de 120fps aplicada!", 3)
    end
end)
