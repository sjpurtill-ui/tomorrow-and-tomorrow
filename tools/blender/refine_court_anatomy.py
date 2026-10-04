"""Refine only the exported Body nose/ears; retain all other GLB payloads.

Run with Python + numpy, from the project: --source-ref <pristine commit>.
The regular Blender exporter also calls refine_file after its fresh export.
Local conforming subdivision carries every skin attribute and morph target.
The original binary chunk stays intact; replacement Body accessors are appended.
"""
import argparse
import copy
import json
from pathlib import Path
import struct
import subprocess
import numpy as np

from validate_court_wardrobe import GLB, DT, SZ


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def nose_displacement(p):
    """Bridge, rounded tip, alae and two shallow underside recesses."""
    x, y, z = p.T
    ax = np.abs(x)
    front = smooth(.063, .085, z)
    support = (1 - smooth(.025, .034, ax)) * smooth(.067, .076, y) * (1 - smooth(.143, .156, y)) * front
    def bump(cx, cy, rx, ry):
        return np.exp(-2 * (((ax - cx) / rx) ** 2 + ((y - cy) / ry) ** 2))
    d = np.zeros_like(p)
    # Dorsum tapers into the brow. The tip has a short, rounded underside,
    # separated from the lip instead of a featureless slope down the face.
    d[:, 2] = .010 * bump(0, .122, .010, .028)
    d[:, 2] += .018 * bump(0, .097, .014, .013)
    d[:, 2] += .009 * bump(.015, .090, .008, .009)
    d[:, 2] += .006 * bump(0, .084, .0045, .009)
    d[:, 2] -= .0045 * bump(.0095, .0845, .004, .0044)
    d[:, 2] -= .003 * bump(.022, .093, .003, .011)
    d[:, 1] -= .0018 * bump(0, .094, .012, .010)
    return d * support[:, None]


def region(p):
    x, y, z = p.T
    nose = (abs(x) < .038) & (y > .060) & (y < .162) & (z > .050)
    ears = (abs(x) > .074) & (y > .078) & (y < .172) & (z < .022) & (z > -.050)
    return nose | ears


def subdivide(attrs, targets, triangles, scale, chin, z_offset):
    """Split shared edges consistently, with no T junctions or hard borders."""
    for _ in range(5):
        p = attrs['POSITION']
        q = (p - np.array([0, chin, z_offset])) / scale
        edges = np.unique(np.sort(np.concatenate([triangles[:, [0, 1]], triangles[:, [1, 2]], triangles[:, [2, 0]]]), axis=1), axis=0)
        mid = (q[edges[:, 0]] + q[edges[:, 1]]) * .5
        chosen = region(mid) | region(q[edges[:, 0]]) | region(q[edges[:, 1]])
        spacing = np.where(abs(mid[:, 0]) > .074, .0028, .0032)
        edges = edges[chosen & (np.linalg.norm(q[edges[:, 0]] - q[edges[:, 1]], axis=1) > spacing)]
        if not len(edges):
            break
        count = len(p)
        lookup = {tuple(e): count + i for i, e in enumerate(edges)}
        joints, weights = attrs['JOINTS_0'], attrs['WEIGHTS_0']
        new_j, new_w = [], []
        for a, b in edges:
            influences = {}
            for j, w in zip(np.r_[joints[a], joints[b]], np.r_[weights[a], weights[b]] * .5):
                influences[int(j)] = influences.get(int(j), 0.) + float(w)
            keep = sorted(influences.items(), key=lambda v: -v[1])[:4]
            keep += [(0, 0.)] * (4 - len(keep))
            total = sum(v for _, v in keep)
            new_j.append([j for j, _ in keep]); new_w.append([v / total for _, v in keep])
        # Phong edge interpolation follows the authored smooth head surface.
        # Linear splits would turn each original broad triangle into a flat
        # patch with a narrow smoothing crease after normals are recomputed.
        def rounded_middle(points, ns):
            ns = ns / np.maximum(np.linalg.norm(ns, axis=1, keepdims=True), 1e-12)
            pa, pb = points[edges[:, 0]], points[edges[:, 1]]
            na, nb = ns[edges[:, 0]], ns[edges[:, 1]]
            mid = (pa + pb) * .5
            # Keep the original skin plane underneath the separate eyebrow
            # decals: smoothing up into the brow can push skin through them.
            face_y = (mid[:, 1] - chin) / scale
            clearance = np.where(abs(mid[:, 0] / scale) < .05, 1 - smooth(.130, .149, face_y), 1.)
            return mid + (.35 * clearance[:, None]) * (np.sum((pa - mid) * na, axis=1)[:, None] * na + np.sum((pb - mid) * nb, axis=1)[:, None] * nb)
        rounded = rounded_middle(p, attrs['NORMAL'])
        target_midpoints = [rounded_middle(p + t['POSITION'], attrs['NORMAL'] + t.get('NORMAL', 0)) - rounded for t in targets]
        for array_index, arrays in enumerate([attrs] + targets):
            for key, values in list(arrays.items()):
                addition = (values[edges[:, 0]].astype(float) + values[edges[:, 1]].astype(float)) * .5
                if key == 'POSITION': addition = rounded if arrays is attrs else target_midpoints[array_index - 1]
                if arrays is attrs and key == 'JOINTS_0': addition = new_j
                if arrays is attrs and key == 'WEIGHTS_0': addition = new_w
                if np.issubdtype(values.dtype, np.integer): addition = np.rint(addition)
                arrays[key] = np.concatenate([values, np.asarray(addition, dtype=values.dtype)])
        out = []
        for a, b, c in triangles:
            ab = lookup.get(tuple(sorted((a, b))))
            bc = lookup.get(tuple(sorted((b, c))))
            ca = lookup.get(tuple(sorted((c, a))))
            n = sum(i is not None for i in (ab, bc, ca))
            if n == 0: out.append((a, b, c))
            elif n == 3: out.extend([(a, ab, ca), (ab, b, bc), (ca, bc, c), (ab, bc, ca)])
            elif n == 1:
                if ab is not None: out.extend([(a, ab, c), (ab, b, c)])
                elif bc is not None: out.extend([(b, bc, a), (bc, c, a)])
                else: out.extend([(c, ca, b), (ca, a, b)])
            elif ca is None: out.extend([(b, bc, ab), (a, ab, c), (ab, bc, c)])
            elif ab is None: out.extend([(c, ca, bc), (b, bc, a), (bc, ca, a)])
            else: out.extend([(a, ab, ca), (c, ca, b), (ca, ab, b)])
        triangles = np.array(out, dtype=np.uint32)
    return triangles


def normals(p, triangles):
    result = np.zeros_like(p)
    tri = p[triangles]
    cross = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    for corner in range(3):
        np.add.at(result, triangles[:, corner], cross)
    return result / np.maximum(np.linalg.norm(result, axis=1, keepdims=True), 1e-12)


def refine_file(source, destination=None, ears=True):
    if ears:
        from court_ear_anatomy import ear_displacement
    g = GLB(str(source))
    body_name = next(n['name'] for n in g.doc['nodes'] if n.get('name') in ('Body', 'LegacyBody', 'WardrobeBody'))
    mesh = g.mesh(body_name)
    if mesh.get('extras', {}).get('anatomy_revision'):
        raise ValueError('Already refined: use an original export or --source-ref')
    primitive = mesh['primitives'][0]
    attrs = {k: g.values(v) for k, v in primitive['attributes'].items()}
    targets = [{k: g.values(v) for k, v in t.items()} for t in primitive['targets']]
    original_count = len(attrs['POSITION'])
    uv, p = attrs['TEXCOORD_0'], attrs['POSITION']
    valid = abs(uv[:, 0]) > .01
    scale = float(np.median(p[valid, 0] / uv[valid, 0]))
    chin = float(np.median(p[:, 1] - (1 - uv[:, 1]) * scale))
    z_offset = .020 if '_old' in str(source) else 0.
    triangles = g.values(primitive['indices']).reshape(-1, 3).astype(np.uint32)
    triangles = subdivide(attrs, targets, triangles, scale, chin, z_offset)
    rest = attrs['POSITION'].copy()
    q = (rest - [0, chin, z_offset]) / scale
    active = region(q)
    active[np.unique(triangles[np.any(active[triangles], axis=1)])] = True
    def sculpt(points):
        q = (points - [0, chin, z_offset]) / scale
        return points + scale * (nose_displacement(q) + (ear_displacement(q) if ears else 0))
    attrs['POSITION'] = sculpt(rest).astype(np.float32)
    attrs['NORMAL'][active] = normals(attrs['POSITION'], triangles)[active]
    # Face-space projection tracks the sculpted skin. Recalculate facing
    # only in the refined region; clothing coverage/AO remain original.
    attrs['TEXCOORD_1'][active, 0] = np.maximum(0, attrs['NORMAL'][active, 2])
    for target in targets:
        absolute = sculpt(rest + target['POSITION']).astype(np.float32)
        target['POSITION'][active] = (absolute - attrs['POSITION'])[active]
        if 'NORMAL' in target:
            target['NORMAL'][active] = normals(absolute, triangles)[active] - attrs['NORMAL'][active]
    binary = bytearray(g.bin)
    def append(values, original=None, index=False):
        values = np.ascontiguousarray(values)
        if values.ndim == 1: values = values[:, None]
        while len(binary) % 4: binary.append(0)
        view = len(g.doc['bufferViews'])
        g.doc['bufferViews'].append({'buffer': 0, 'byteOffset': len(binary), 'byteLength': values.nbytes})
        binary.extend(values.tobytes())
        acc = copy.deepcopy(g.doc['accessors'][original]) if original is not None else {'componentType': 5125, 'type': 'SCALAR'}
        acc.pop('sparse', None); acc.pop('byteOffset', None)
        acc.update(bufferView=view, count=len(values))
        if 'min' in acc or index: acc['min'] = values.min(axis=0).tolist()
        if 'max' in acc or index: acc['max'] = values.max(axis=0).tolist()
        result = len(g.doc['accessors']); g.doc['accessors'].append(acc)
        return result
    for k, values in attrs.items():
        primitive['attributes'][k] = append(values, primitive['attributes'][k])
    for source_target, target in zip(primitive['targets'], targets):
        for k, values in target.items(): source_target[k] = append(values, source_target[k])
    primitive['indices'] = append(triangles.reshape(-1), index=True)
    mesh['extras']['anatomy_revision'] = 1
    g.doc['buffers'][0]['byteLength'] = len(binary)
    doc = json.dumps(g.doc, separators=(',', ':')).encode()
    doc += b' ' * (-len(doc) % 4)
    binary += b'\0' * (-len(binary) % 4)
    raw = struct.pack('<III', 0x46546c67, 2, 28 + len(doc) + len(binary)) + struct.pack('<II', len(doc), 0x4e4f534a) + doc + struct.pack('<II', len(binary), 0x004e4942) + binary
    output = Path(destination or source)
    temporary = output.with_suffix('.anatomy-tmp')
    temporary.write_bytes(raw)
    temporary.replace(output)
    return {'vertices_before': original_count, 'vertices_after': len(rest), 'triangles': len(triangles)}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--source-ref', required=True)
    ap.add_argument('--variants', default='male_adult,female_adult,male_old,female_old,male_young,female_young,child')
    ap.add_argument('--nose-only', action='store_true')
    args = ap.parse_args()
    root = Path(__file__).resolve().parents[2]
    saved = root / 'artifacts' / 'anatomy-original'
    saved.mkdir(parents=True, exist_ok=True)
    for variant in args.variants.split(','):
        for folder, stem in [('', 'figure'), ('legacy/', 'legacy'), ('wardrobe/', 'wardrobe')]:
            relative = 'assets/court_figures/' + folder + 'court_' + stem + '_' + variant + '.glb'
            raw = subprocess.check_output(['git', 'show', args.source_ref + ':' + relative], cwd=root)
            source = saved / Path(relative).name
            source.write_bytes(raw)
            print(Path(relative).name, refine_file(source, root / relative, ears=not args.nose_only), flush=True)


if __name__ == '__main__':
    main()
