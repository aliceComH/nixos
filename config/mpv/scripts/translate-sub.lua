local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local enabled = true
local original_sub_visibility = true
local overlay = mp.create_osd_overlay("ass-events")
local current_sub_text = ""
local translate_seq = 0

local lt_url = "http://localhost:5000/translate"

local function clear_overlay()
    overlay.data = ""
    overlay:update()
end

local function draw_sub(text)
    -- Troca quebras de linha normais pela tag do ASS
    local safe_text = string.gsub(text, "\n", "\\N")
    
    -- Formatação: alinhado na base central (an2), fonte tamanho 40, borda e sombra suaves.
    local ass = string.format("{\\an2}{\\b0}{\\fs42}{\\bord2}{\\shad1}%s", safe_text)
    
    overlay.data = ass
    overlay:update()
end

local function translate_text(text)
    if text == "" then
        clear_overlay()
        return
    end

    translate_seq = translate_seq + 1
    local seq = translate_seq

    local payload = utils.format_json({
        q = text,
        source = "en",
        target = "pt",
        format = "text"
    })

    -- Usa luasocket em vez de subprocess para evitar fork() no mpv e travamento na GPU (AMDGPU + Vulkan)
    local http = require("socket.http")
    local ltn12 = require("ltn12")

    local response_body = {}
    local res, code, response_headers, status = http.request{
        url = lt_url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#payload)
        },
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(response_body)
    }

    if seq ~= translate_seq then return end

    if code == 200 then
        local result_str = table.concat(response_body)
        local json, parse_err = utils.parse_json(result_str)
        if json and json.translatedText then
            draw_sub(json.translatedText)
        else
            msg.error("Erro na tradução ou JSON inválido")
        end
    else
        msg.error("HTTP request falhou: " .. tostring(code))
    end
end

local function on_sub_change(name, text)
    current_sub_text = text or ""
    if not enabled then return end
    translate_text(current_sub_text)
end

local function toggle_translation()
    enabled = not enabled
    if enabled then
        mp.osd_message("Tradução: ON", 2)
        original_sub_visibility = mp.get_property_native("sub-visibility")
        if original_sub_visibility ~= nil then
            mp.set_property_native("sub-visibility", false)
        end
        translate_text(current_sub_text)
    else
        mp.osd_message("Tradução: OFF", 2)
        if original_sub_visibility ~= nil then
            mp.set_property_native("sub-visibility", original_sub_visibility)
        end
        clear_overlay()
    end
end

mp.register_event("file-loaded", function()
    if enabled then
        local vis = mp.get_property_native("sub-visibility")
        if vis ~= nil then
            original_sub_visibility = vis
            mp.set_property_native("sub-visibility", false)
        end
    end
end)

mp.add_key_binding("ctrl+t", "toggle-translation", toggle_translation)
mp.observe_property("sub-text", "string", on_sub_change)
