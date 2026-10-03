"""Court acting (K): a PNG sequence (from tools/court_acting_capture.gd "room")
made into an H.264 .mp4 with Blender's own ffmpeg (no other tools needed).

  blender --background --factory-startup --python tools/blender/court_anims_video.py -- <frames_dir> <out.mp4> [fps]
"""
import os
import sys

import bpy


def main():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    frames_dir, out = os.path.abspath(a[0]), os.path.abspath(a[1])
    fps = int(a[2]) if len(a) > 2 else 30
    files = sorted(f for f in os.listdir(frames_dir) if f.lower().endswith(".png"))
    sc = bpy.context.scene
    sc.sequence_editor_create()
    se = sc.sequence_editor
    strips = se.strips if hasattr(se, "strips") else se.sequences
    strip = strips.new_image("frames", os.path.join(frames_dir, files[0]), 1, 1)
    for f in files[1:]:
        strip.elements.append(f)
    sc.frame_start = 1
    sc.frame_end = len(files)
    sc.render.fps = fps
    first = bpy.data.images.load(os.path.join(frames_dir, files[0]))
    sc.render.resolution_x, sc.render.resolution_y = first.size
    sc.render.resolution_percentage = 100
    if hasattr(sc.render.image_settings, 'media_type'):
        sc.render.image_settings.media_type = 'VIDEO'
    sc.render.image_settings.file_format = 'FFMPEG'
    sc.render.ffmpeg.format = 'MPEG4'
    sc.render.ffmpeg.codec = 'H264'
    sc.render.ffmpeg.constant_rate_factor = 'HIGH'
    sc.render.filepath = out
    bpy.ops.render.render(animation=True)
    print("[court_anims_video] wrote", out, len(files), "frames", flush=True)


if __name__ == "__main__":
    main()
