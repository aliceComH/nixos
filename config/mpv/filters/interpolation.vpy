import vapoursynth as vs
core = vs.core

clip = video_in
width = clip.width

# ── Target FPS dinâmico ──
target_fps = 120  # Lockado em 120fps

# ── Detecção de HDR e Tone Mapping ──
props = clip.get_frame(0).props
transfer = props.get("_Transfer", 1)
primaries = props.get("_Primaries", 1)
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

# ── Downscale 4K→1080p para análise de vetores ──
if width > 1920:
    target_w = 1920
    target_h = int(target_w * (clip.height / clip.width))
    target_h = target_h - (target_h % 2)
    target_w = target_w - (target_w % 2)
    clip = core.resize.Bicubic(clip, width=target_w, height=target_h)

# ── Preparação do clip de análise (8-bit para MVTools) ──
clip_analise = core.resize.Bicubic(clip, format=vs.YUV420P8)

# ── FPS handling ──
src_fps_num = int(container_fps * 1e8)
src_fps_den = int(1e8)
dst_fps_num = int(target_fps * 1e4)
dst_fps_den = int(1e4)

clip = core.std.AssumeFPS(clip, fpsnum=src_fps_num, fpsden=src_fps_den)
clip_analise = core.std.AssumeFPS(clip_analise, fpsnum=src_fps_num, fpsden=src_fps_den)

# ── Motion Analysis ──
# pel=2: sub-pixel precision (qualidade superior, CPU aguenta)
# blksize=16: blocos menores = vetores mais precisos
# overlap=8: sobreposição de blocos para transições suaves
# search=3: hex search — bom balanço velocidade/precisão
b_size = 16
b_overlap = 8

sup_analise = core.mv.Super(clip_analise, pel=2, hpad=b_size, vpad=b_size)

bvec = core.mv.Analyse(
    sup_analise, blksize=b_size, overlap=b_overlap,
    isb=True, chroma=True, search=3, searchparam=2
)
fvec = core.mv.Analyse(
    sup_analise, blksize=b_size, overlap=b_overlap,
    isb=False, chroma=True, search=3, searchparam=2
)

# ── Interpolação com FlowFPS ──
# FlowFPS é MUITO superior ao BlockFPS:
#   - Usa optical flow (compensação de movimento pixel-a-pixel)
#   - Menos artefatos de "bloco" em cenas com movimento rápido
#   - É o que o SVP usa internamente
sup_render = core.mv.Super(clip, pel=2, hpad=b_size, vpad=b_size)
clip = core.mv.FlowFPS(
    clip, sup_render, bvec, fvec,
    num=dst_fps_num, den=dst_fps_den,
    mask=2,     # Máscara de oclusão (2 = melhor qualidade)
    thscd2=12,  # Threshold de scene change
)

clip.set_output()

