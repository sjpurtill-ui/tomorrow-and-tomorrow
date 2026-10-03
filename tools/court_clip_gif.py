"""Turns a court clip's frames (reports/court_figures/clip_<tag>/fNNNN.png,
written by tests/court_stage_clip.tscn) into an animated GIF beside them.
Crops to the stage when asked, so the hall fills the picture.

  python tools/court_clip_gif.py reports/court_figures/clip_home [--crop x0,y0,x1,y1] [--width 960] [--fps 12]
"""
import sys
import glob
import os
from PIL import Image


def main():
    a = sys.argv[1:]
    folder = a[0]
    crop = None
    width = 960
    fps = 12
    for i, x in enumerate(a):
        if x == "--crop":
            crop = tuple(int(v) for v in a[i + 1].split(","))
        if x == "--width":
            width = int(a[i + 1])
        if x == "--fps":
            fps = int(a[i + 1])
    frames = sorted(glob.glob(os.path.join(folder, "f*.png")))
    if not frames:
        print("no frames in", folder)
        return 1
    images = []
    for path in frames:
        im = Image.open(path).convert("RGB")
        if crop:
            im = im.crop(crop)
        h = int(im.height * width / im.width)
        images.append(im.resize((width, h), Image.LANCZOS).quantize(colors=200, method=Image.Quantize.MEDIANCUT))
    out = folder.rstrip("/\\") + ".gif"
    images[0].save(out, save_all=True, append_images=images[1:], duration=int(1000 / fps), loop=0, optimize=True)
    print("wrote", out, len(images), "frames")
    return 0


if __name__ == "__main__":
    sys.exit(main())
