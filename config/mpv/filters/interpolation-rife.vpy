import vapoursynth as vs
core = vs.core

# ── Alocação de Recursos (Crucial para não gargalar a GPU) ───────────────
# Reserva threads do seu i5 e garante 8GB de RAM para o buffer do VS
core.num_threads = 14
core.max_cache_size = 8192 

clip = video_in
width = clip.width

# ── Target FPS ───────────────────────────────────────────────────────────
factor_num = 2
factor_den = 1

# ── Detecção de HDR e Tone Mapping para SDR ──────────────────────────────
# Se o conteúdo é HDR (PQ/HLG + BT.2020), converte para SDR antes do RIFE.
# Sem isso, a conversão RGBS com matrix_in_s="709" distorce todas as cores.
props = clip.get_frame(0).props

# Detecta HDR pelas propriedades do frame: Transfer (PQ=16, HLG=18) ou Primaries (BT.2020=9)
transfer = props.get("_Transfer", 1)     # 1 = BT.709 (SDR default)
primaries = props.get("_Primaries", 1)    # 1 = BT.709
matrix = props.get("_Matrix", 1)          # 1 = BT.709

is_hdr = transfer in (16, 18) or primaries == 9

if is_hdr:
    # Converte HDR → SDR: BT.2020+PQ → BT.709 com tone mapping via zimg.
    # O resize.Bicubic do zimg suporta tone mapping nativo quando muda
    # de transfer_in_s="st2084" para transfer_s="709".
    clip = core.resize.Bicubic(
        clip,
        format=vs.YUV420P10,          # Mantém 10-bit durante o tonemap para preservar gradients
        matrix_in_s="2020ncl",
        matrix_s="709",
        transfer_in_s="st2084",
        transfer_s="709",
        primaries_in_s="2020",
        primaries_s="709",
        nominal_luminance=1000,        # Luminância de pico assumida do master HDR
    )
    # Após tonemap, o clip é SDR em BT.709 — pode seguir normalmente
    color_matrix = "709"
else:
    color_matrix = "709"

# ── Downscale em 4K ──────────────────────────────────────────────────────
if width > 1920:
    target_w = 1920
    target_h = int(target_w * (clip.height / clip.width))
    target_h = target_h - (target_h % 2)
    target_w = target_w - (target_w % 2)
    # Alterado para Bilinear: Mais rápido em CPU para downscale inicial, 
    # sem perda perceptível de qualidade na conversão 4K -> 1080p
    clip = core.resize.Bilinear(clip, width=target_w, height=target_h)

# ── Conversão para RGBS ──────────────────────────────────────────────────
original_format = clip.format.id
clip = core.resize.Bicubic(clip, format=vs.RGBS, matrix_in_s=color_matrix)

# ── RIFE: Interpolação via GPU (Vulkan) ──────────────────────────────────
clip = core.rife.RIFE(
    clip,
    model=23,           # rife-v4.6
    factor_num=factor_num,
    factor_den=factor_den,
    gpu_id=0,
    gpu_thread=2,       # Reduzido para 2 para alinhar com o pipeline de Vulkan sem floodar a VRAM
    sc=False,           # Desativado: A detecção de mudança de cena exige processamento prévio. Ganho puro de FPS.
    skip=False,
    uhd=False,
)

# ── Conversão de volta para YUV420P ──────────────────────────────────────
clip = core.resize.Bicubic(clip, format=original_format, matrix_s=color_matrix)

# ── Declaração de FPS para o Wayland/Hyprland ────────────────────────────
# É vital injetar o framerate correto nos metadados para que o video-sync=display-resample
# do mpv consiga sincronizar os quadros com o VSync do seu monitor sob o Hyprland.
src_fps_num = int(container_fps * 1e8)
src_fps_den = int(1e8)
clip = core.std.AssumeFPS(clip, fpsnum=src_fps_num * factor_num, fpsden=src_fps_den * factor_den)

clip.set_output()

