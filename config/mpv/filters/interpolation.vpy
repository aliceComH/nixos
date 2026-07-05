import vapoursynth as vs
core = vs.core

clip = video_in
width = clip.width

# 1. O Cérebro: Lógica Dinâmica de FPS baseada na Resolução Bruta
if width <= 1920:
    target_fps = 180  # 1080p ou menor
elif width > 1920:
    target_fps = 120   # 4K

# ── Detecção de HDR e Tone Mapping para SDR ──────────────────────────────
# Se o conteúdo é HDR (PQ/HLG + BT.2020), converte para SDR antes do MVTools.
# Sem isso, a conversão direta de 10-bit HDR para 8-bit esmaga a faixa dinâmica
# inteira — os vetores de movimento ficam imprecisos e o vídeo tem banding brutal.
props = clip.get_frame(0).props

transfer = props.get("_Transfer", 1)     # 1 = BT.709 (SDR default)
primaries = props.get("_Primaries", 1)    # 1 = BT.709

is_hdr = transfer in (16, 18) or primaries == 9

if is_hdr:
    clip = core.resize.Bicubic(
        clip,
        format=vs.YUV420P10,
        matrix_in_s="2020ncl",
        matrix_s="709",
        transfer_in_s="st2084",
        transfer_s="709",
        primaries_in_s="2020",
        primaries_s="709",
        nominal_luminance=1000,
    )

# Mantemos o "Cheat Code" do 1080p para salvar a sua CPU no 4K/8K
if width > 1920:
    target_w = 1920
    target_h = int(target_w * (clip.height / clip.width))
    # Força dimensões pares — YUV420 exige isso pelo subsampling de chroma
    target_h = target_h - (target_h % 2)
    target_w = target_w - (target_w % 2)
    clip = core.resize.Bicubic(clip, width=target_w, height=target_h)

clip_analise = core.resize.Bicubic(clip, format=vs.YUV420P8)

# Transformando a nossa variável em denominadores precisos para o VapourSynth
src_fps_num = int(container_fps * 1e8)
src_fps_den = int(1e8)
dst_fps_num = int(target_fps * 1e4)
dst_fps_den = int(1e4)

clip = core.std.AssumeFPS(clip, fpsnum=src_fps_num, fpsden=src_fps_den)
clip_analise = core.std.AssumeFPS(clip_analise, fpsnum=src_fps_num, fpsden=src_fps_den)

b_size = 32
b_overlap = 8

sup_analise = core.mv.Super(clip_analise, pel=1, hpad=b_size, vpad=b_size)

# Busca Diamante (search=2) para manter a latência no chão
bvec = core.mv.Analyse(sup_analise, blksize=b_size, overlap=b_overlap, isb=True, chroma=True, search=2)
fvec = core.mv.Analyse(sup_analise, blksize=b_size, overlap=b_overlap, isb=False, chroma=True, search=2)

sup_render = core.mv.Super(clip, pel=1, hpad=b_size, vpad=b_size)
clip = core.mv.BlockFPS(clip, sup_render, bvec, fvec, num=dst_fps_num, den=dst_fps_den, mode=3, thscd2=12)

clip.set_output()

