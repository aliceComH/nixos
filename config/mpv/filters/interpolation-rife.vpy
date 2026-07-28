import vapoursynth as vs
core = vs.core

core.num_threads = 8
core.max_cache_size = 12288

clip = video_in
width = clip.width
factor_num = 2
factor_den = 1

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
    color_matrix = "709"
else:
    color_matrix = "709"

if width > 1920:
    target_w = 1920
    target_h = int(target_w * (clip.height / clip.width))
    target_h = target_h - (target_h % 2)
    target_w = target_w - (target_w % 2)
    clip = core.resize.Bicubic(clip, width=target_w, height=target_h)

original_format = clip.format.id
clip = core.resize.Bicubic(clip, format=vs.RGBS, matrix_in_s=color_matrix)

clip = core.rife.RIFE(
    clip,
    model=23,
    factor_num=factor_num,
    factor_den=factor_den,
    gpu_id=0,
    gpu_thread=1,
    sc=False,
    skip=False,
    uhd=False,
)

clip = core.resize.Bicubic(clip, format=original_format, matrix_s=color_matrix)

src_fps_num = int(container_fps * 1e8)
src_fps_den = int(1e8)
clip = core.std.AssumeFPS(clip, fpsnum=src_fps_num * factor_num, fpsden=src_fps_den * factor_den)

clip.set_output()
