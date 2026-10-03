"""Prove a clothing refit changed only garment weights and body cover channels.

python tools/blender/validate_clothing_refit.py <source-directory> <result-directory>
No Blender or third-party modules required.
"""
import json
from pathlib import Path
import struct
import sys

SIZES = {5121: 1, 5123: 2, 5125: 4, 5126: 4}
WIDTHS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
GARMENTS = ('hide_wrap', 'tunic_body', 'tunic_trim', 'robe_body', 'robe_trim', 'robe_mantle')


def validate(source, result):
    original = bytearray(source.read_bytes())
    changed = bytearray(result.read_bytes())
    assert len(original) == len(changed), 'Asset size changed'
    json_size = struct.unpack_from('<I', original, 12)[0]
    start = 28 + json_size
    assert original[:start] == changed[:start], 'GLB structure or JSON changed'
    document = json.loads(original[20:20 + json_size])
    ranges = []

    def layout(index):
        accessor = document['accessors'][index]
        view = document['bufferViews'][accessor['bufferView']]
        size = SIZES[accessor['componentType']]
        width = WIDTHS[accessor['type']]
        return (start + view.get('byteOffset', 0) + accessor.get('byteOffset', 0),
                view.get('byteStride', size * width), accessor['count'], size, width,
                accessor['componentType'])

    for node in document['nodes']:
        if 'mesh' not in node or 'skin' not in node:
            continue
        name = node.get('name', '')
        for primitive in document['meshes'][node['mesh']]['primitives']:
            attrs = primitive['attributes']
            if name.startswith(GARMENTS):
                for key in ('JOINTS_0', 'WEIGHTS_0'):
                    offset, stride, count, size, width, kind = layout(attrs[key])
                    for vertex in range(count):
                        at = offset + vertex * stride
                        ranges.append((at, at + size * width))
                        if key == 'WEIGHTS_0':
                            assert kind == 5126 and width == 4
                            weights = struct.unpack_from('<4f', changed, at)
                            assert all(0.0 <= value <= 1.0 for value in weights)
                            assert abs(sum(weights) - 1.0) < 0.0001
                        else:
                            assert width == 4 and kind in (5121, 5123)
                            joints = struct.unpack_from('<4' + ('B' if kind == 5121 else 'H'), changed, at)
                            assert max(joints) < len(document['skins'][node['skin']]['joints'])
            elif name == 'Body':
                offset, stride, count, size, width, _ = layout(attrs['COLOR_0'])
                assert width == 4
                for vertex in range(count):
                    at = offset + vertex * stride
                    ranges.append((at + size, at + 4 * size))
    assert ranges
    for first, last in ranges:
        original[first:last] = bytes(last - first)
        changed[first:last] = bytes(last - first)
    assert original == changed, 'A geometry, AO, face morph, skeleton, animation or other byte changed'
    print('CLOTHING_BUFFER_CHECK PASS', source.name)


if __name__ == '__main__':
    source_dir, result_dir = map(Path, sys.argv[1:3])
    figures = sorted(source_dir.glob('court_figure_*.glb'))
    assert len(figures) == 7, 'Expected all seven body variants'
    for figure in figures:
        validate(figure, result_dir / figure.name)
