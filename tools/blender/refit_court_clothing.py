"""Refit exported court clothes without regenerating geometry, AO or animation.

Blender --background --factory-startup --python tools/blender/refit_court_clothing.py
  -- --source <original-figure-folder> --out <result-folder> [--variants female_old]

The regular figure builder uses the same final weight field. This helper changes
only JOINTS_0 / WEIGHTS_0 for the garments and G/B/A skin coverage; all geometry,
face morphs, AO, skeleton rests and animation bytes are preserved verbatim.
Use pristine, pre-refit assets as the source; smoothing is not idempotent.
"""
import argparse
import json
import os
import struct
import sys

import bpy
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cf_body
import cf_dress
import cf_rig
import court_figures as figures

COMPONENTS = {5120: 'i1', 5121: 'u1', 5122: '<i2', 5123: '<u2', 5125: '<u4', 5126: '<f4'}
WIDTHS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}


class GLB:
    def __init__(self, path):
        with open(path, 'rb') as handle:
            self.raw = bytearray(handle.read())
        magic, version, size = struct.unpack_from('<III', self.raw)
        assert magic == 0x46546C67 and version == 2 and size == len(self.raw)
        count, kind = struct.unpack_from('<II', self.raw, 12)
        assert kind == 0x4E4F534A
        self.doc = json.loads(self.raw[20:20 + count])
        self.start = 20 + count + 8
        assert struct.unpack_from('<I', self.raw, self.start - 4)[0] == 0x004E4942

    def array(self, index):
        accessor = self.doc['accessors'][index]
        view = self.doc['bufferViews'][accessor['bufferView']]
        dtype = np.dtype(COMPONENTS[accessor['componentType']])
        width = WIDTHS[accessor['type']]
        offset = self.start + view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
        stride = view.get('byteStride', width * dtype.itemsize)
        return np.ndarray((accessor['count'], width), dtype=dtype,
                          buffer=self.raw, offset=offset, strides=(stride, dtype.itemsize))


def refit(source, destination, variant):
    figures.clear_scene()
    bpy.ops.import_scene.gltf(filepath=source)
    frame = cf_body.Frame(cf_body.params(variant))
    body = bpy.data.objects['Body']
    masks = {}
    for outfit in cf_dress.OUTFITS:
        pieces = cf_dress.outfit(frame, outfit)
        objects = [bpy.data.objects[pc.name] for pc in pieces if pc.name in bpy.data.objects]
        for obj in objects:
            figures._refine_garment_weights(obj, frame)
        masks[outfit] = cf_dress.coverage(body, pieces, strict=figures._arm_vertices(body), objs=objects)
    glb = GLB(source)
    doc = glb.doc
    changed = 0
    for node in doc['nodes']:
        if 'mesh' not in node or 'skin' not in node:
            continue
        name = node['name']
        obj = bpy.data.objects.get(name)
        is_cloth = name.startswith(('hide_wrap', 'tunic_body', 'tunic_trim', 'robe_body', 'robe_trim', 'robe_mantle'))
        if obj is None or not (is_cloth or name == 'Body'):
            continue
        kd = KDTree(len(obj.data.vertices))
        for vertex in obj.data.vertices:
            kd.insert(vertex.co, vertex.index)
        kd.balance()
        weights = cf_rig._weights_table(obj)
        joint_names = [doc['nodes'][joint]['name'] for joint in doc['skins'][node['skin']]['joints']]
        for primitive in doc['meshes'][node['mesh']]['primitives']:
            attrs = primitive['attributes']
            positions = glb.array(attrs['POSITION'])
            ids = []
            for position in positions:
                _, index, distance = kd.find(Vector((float(position[0]), -float(position[2]), float(position[1]))))
                assert distance < 0.00001, (variant, name, distance)
                ids.append(index)
            if is_cloth:
                joints = glb.array(attrs['JOINTS_0'])
                values = glb.array(attrs['WEIGHTS_0'])
                assert values.dtype == np.dtype('<f4')
                for row, index in enumerate(ids):
                    items = sorted(weights[index].items(), key=lambda item: -item[1])[:4]
                    total = sum(value for _, value in items)
                    joints[row] = 0
                    values[row] = 0
                    for column, (bone, value) in enumerate(items):
                        joints[row, column] = joint_names.index(bone)
                        values[row, column] = value / total
            else:
                colors = glb.array(attrs['COLOR_0'])
                high = np.iinfo(colors.dtype).max if colors.dtype.kind in 'iu' else 1.0
                for outfit, channel in figures.OUTFIT_CHANNEL.items():
                    colors[:, channel] = masks[outfit][ids] * high
            changed += 1
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    with open(destination, 'wb') as handle:
        handle.write(glb.raw)
    print('CLOTHING_REFIT', variant, changed, 'surfaces;',
          ', '.join('%s hides %s vertices' % (kind, int(mask.sum())) for kind, mask in masks.items()), flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', required=True)
    parser.add_argument('--out', required=True)
    parser.add_argument('--variants', default=','.join(cf_body.VARIANTS))
    opts = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    if os.path.normcase(os.path.abspath(opts.source)) == os.path.normcase(os.path.abspath(opts.out)):
        parser.error('--out must differ from --source so the pristine source stays available')
    for variant in opts.variants.split(','):
        name = 'court_figure_%s.glb' % variant
        refit(os.path.abspath(os.path.join(opts.source, name)), os.path.abspath(os.path.join(opts.out, name)), variant)


if __name__ == '__main__':
    main()
