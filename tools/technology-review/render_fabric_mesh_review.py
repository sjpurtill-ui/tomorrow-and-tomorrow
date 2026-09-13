"""CPU projections of exported Godot mesh triangles; not a GPU screenshot.
Usage: python render_fabric_mesh_review.py before.json after.json review.png
"""
import json
import sys
import numpy as np
from PIL import Image, ImageDraw

size = 380
right = np.array([.8, 0, -.6])
up = np.array([-.3, .8660254, -.4])
depth = np.cross(right, up)
light = np.array([.3, .85, .4]); light /= np.linalg.norm(light)

def render(record):
    pixels = np.full((size, size, 3), [242, 239, 230], dtype=np.uint8)
    buffer = np.full((size, size), -np.inf)
    for row in record['triangles']:
        v = np.array(row[:3], dtype=float)
        x = v @ right * 20 + size / 2
        y = size - 110 - v @ up * 20
        z = v @ depth
        lo = np.maximum([0, 0], np.floor([min(x), min(y)]).astype(int))
        hi = np.minimum([size-1, size-1], np.ceil([max(x), max(y)]).astype(int))
        if np.any(lo > hi): continue
        denominator = (y[1]-y[2])*(x[0]-x[2])+(x[2]-x[1])*(y[0]-y[2])
        if abs(denominator) < 1e-10: continue
        xx, yy = np.meshgrid(np.arange(lo[0],hi[0]+1)+.5, np.arange(lo[1],hi[1]+1)+.5)
        a=((y[1]-y[2])*(xx-x[2])+(x[2]-x[1])*(yy-y[2]))/denominator
        b=((y[2]-y[0])*(xx-x[2])+(x[0]-x[2])*(yy-y[2]))/denominator
        c=1-a-b
        zz=a*z[0]+b*z[1]+c*z[2]
        sub=buffer[lo[1]:hi[1]+1,lo[0]:hi[0]+1]
        mask=(a>=-1e-7)&(b>=-1e-7)&(c>=-1e-7)&(zz>sub)
        normal=np.cross(v[1]-v[0],v[2]-v[0]); length=np.linalg.norm(normal)
        shade=.65+.35*abs(float(normal@light)/length) if length else 1
        color=np.clip(np.array(row[3])*255*shade,0,255).astype(np.uint8)
        pixels[lo[1]:hi[1]+1,lo[0]:hi[0]+1][mask]=color
        sub[mask]=zz[mask]
    return Image.fromarray(pixels)

canvas=Image.new('RGB',(size*4,size*2+70),'#f2efe6')
draw=ImageDraw.Draw(canvas)
draw.text((16,10),'EXPORTED GODOT GEOMETRY — CPU PROJECTION, NOT IN-GAME LIGHTING',fill='#242422')
for row, path in enumerate(sys.argv[1:3]):
    records=json.load(open(path))
    for col, record in enumerate(records):
        x,y=col*size,row*size+50
        canvas.paste(render(record),(x,y))
        draw.text((x+15,y+5),('BEFORE' if row==0 else 'AFTER')+' / '+record['name'],fill='#242422')
canvas.save(sys.argv[3])
