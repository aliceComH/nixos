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
clip = core.resize.Bicubic(clip, format=vs.RGBS, matrix_in_s="709")

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
clip = core.resize.Bicubic(clip, format=original_format, matrix_s="709")

# ── Declaração de FPS para o Wayland/Hyprland ────────────────────────────
# É vital injetar o framerate correto nos metadados para que o video-sync=display-resample
# do mpv consiga sincronizar os quadros com o VSync do seu monitor sob o Hyprland.
src_fps_num = int(container_fps * 1e8)
src_fps_den = int(1e8)
clip = core.std.AssumeFPS(clip, fpsnum=src_fps_num * factor_num, fpsden=src_fps_den * factor_den)

clip.set_output()
