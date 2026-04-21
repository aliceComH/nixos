import vapoursynth as vs
core = vs.core

clip = video_in.resize.Bicubic(format=vs.YUV420P8)

vden = 1000
vfps = int(container_fps * vden)   # ex: 23976 para 23.976fps
dfps = int(display_fps   * vden)   # ex: 120000 para 120fps

clip = core.std.AssumeFPS(clip, fpsnum=vfps, fpsden=vden)
sup  = core.mv.Super(clip, pel=2, sharp=0, rfilter=2)
mvfw = core.mv.Analyse(sup, blksize=32, isb=False, search=3, dct=5)
mvbw = core.mv.Analyse(sup, blksize=32, isb=True,  search=3, dct=5)
clip = core.mv.FlowFPS(clip, sup, mvbw, mvfw, num=dfps, den=vden, mask=1)

clip.set_output()
