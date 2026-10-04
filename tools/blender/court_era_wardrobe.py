"""Build additive court wardrobe bundles, without rebuilding a person's body.

Blender --background --factory-startup --python tools/blender/court_era_wardrobe.py
  -- [--variants male_adult,female_adult,...] [--out assets/court_figures/wardrobe]

Garment shells inherit the delivered skin's exact topology and weights. Tailoring,
collars, lapels, cuffs, fastenings and split skirts are additional geometry. A copy
of the original skin changes only its G coverage channel; all original position,
normal, UV, weight and sparse facial-morph accessors are copied verbatim. The old
three-outfit assets are never written. Bundles contain no animation library.
"""
import argparse
import copy
import hashlib
import json
import math
import os
import struct
import sys

import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import cf_body

KINDS = ("medieval", "courtcoat", "formal", "business")
TYPES = {5121: "u1", 5123: "<u2", 5125: "<u4", 5126: "<f4"}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


class Bundle:
    def __init__(self, path):
        raw = open(path, "rb").read()
        size = struct.unpack_from("<I", raw, 12)[0]
        self.source = json.loads(raw[20:20 + size])
        self.source_bin = raw[28 + size:]
        self.data = bytearray()
        self.views = {}
        self.accessors = {}
        self.doc = {"asset": {"version": "2.0", "generator": "court_era_wardrobe.py"},
                    "buffers": [{"byteLength": 0}], "bufferViews": [], "accessors": [],
                    "materials": copy.deepcopy(self.source["materials"]), "meshes": [],
                    "nodes": copy.deepcopy(self.source["nodes"]), "skins": copy.deepcopy(self.source["skins"]),
                    "scenes": copy.deepcopy(self.source["scenes"]), "scene": self.source.get("scene", 0)}
        self.body_node = next(n for n in self.source["nodes"] if n.get("name") == "Body")
        self.body = self.source["meshes"][self.body_node["mesh"]]
        self.attrs = self.body["primitives"][0]["attributes"]
        self.p = self.array(self.attrs["POSITION"]).copy()
        self.n = self.array(self.attrs["NORMAL"]).copy()
        self.j = self.array(self.attrs["JOINTS_0"]).copy()
        self.w = self.array(self.attrs["WEIGHTS_0"]).copy()
        self.faces = self.array(self.body["primitives"][0]["indices"]).reshape(-1, 3).copy()
        self.names = [self.source["nodes"][i]["name"] for i in self.source["skins"][self.body_node["skin"]]["joints"]]
        self.kd = KDTree(len(self.p))
        for i, p in enumerate(self.p): self.kd.insert(Vector(p), i)
        self.kd.balance()
        for node in self.doc["nodes"]:
            node.pop("mesh", None); node.pop("skin", None); node.pop("weights", None)
        for skin in self.doc["skins"]: skin["inverseBindMatrices"] = self.copy_accessor(skin["inverseBindMatrices"])
        self.parent = next(i for i, n in enumerate(self.doc["nodes"]) if n.get("name") == "Figure")

    def array(self, index):
        a = self.source["accessors"][index]; v = self.source["bufferViews"][a["bufferView"]]
        dtype = np.dtype(TYPES[a["componentType"]]); width = WIDTHS[a["type"]]
        return np.ndarray((a["count"], width), dtype=dtype, buffer=self.source_bin,
                          offset=v.get("byteOffset", 0) + a.get("byteOffset", 0),
                          strides=(v.get("byteStride", dtype.itemsize * width), dtype.itemsize))

    def view(self, data, extra=None):
        while len(self.data) % 4: self.data.append(0)
        view = {"buffer": 0, "byteOffset": len(self.data), "byteLength": len(data)}
        if extra: view.update(extra)
        self.data.extend(data); self.doc["bufferViews"].append(view)
        return len(self.doc["bufferViews"]) - 1

    def copy_view(self, index):
        if index not in self.views:
            v = self.source["bufferViews"][index]
            start = v.get("byteOffset", 0)
            extra = {k: v[k] for k in ("byteStride", "target") if k in v}
            self.views[index] = self.view(self.source_bin[start:start + v["byteLength"]], extra)
        return self.views[index]

    def copy_accessor(self, index):
        if index in self.accessors: return self.accessors[index]
        a = copy.deepcopy(self.source["accessors"][index])
        if "bufferView" in a: a["bufferView"] = self.copy_view(a["bufferView"])
        if "sparse" in a:
            for kind in ("indices", "values"):
                a["sparse"][kind]["bufferView"] = self.copy_view(a["sparse"][kind]["bufferView"])
        self.doc["accessors"].append(a)
        self.accessors[index] = len(self.doc["accessors"]) - 1
        return self.accessors[index]

    def accessor(self, arr, kind, component=5126, normalized=False):
        a = np.asarray(arr, dtype=TYPES[component]).reshape(-1, WIDTHS[kind])
        record = {"bufferView": self.view(a.tobytes()), "componentType": component, "count": len(a), "type": kind}
        if normalized: record["normalized"] = True
        if kind == "VEC3": record.update(min=a.min(axis=0).tolist(), max=a.max(axis=0).tolist())
        self.doc["accessors"].append(record)
        return len(self.doc["accessors"]) - 1

    def body_copy(self, cover):
        mesh = copy.deepcopy(self.body); mesh["name"] = "WardrobeBody"
        for primitive in mesh["primitives"]:
            primitive["indices"] = self.copy_accessor(primitive["indices"])
            primitive["attributes"] = {k: self.copy_accessor(v) for k, v in primitive["attributes"].items()}
            for target in primitive.get("targets", []):
                for k, v in list(target.items()): target[k] = self.copy_accessor(v)
            colors = self.array(self.attrs["COLOR_0"]).copy()
            high = np.iinfo(colors.dtype).max if colors.dtype.kind in "iu" else 1.0
            colors[:, 1] = cover * high
            ca = self.source["accessors"][self.attrs["COLOR_0"]]
            primitive["attributes"]["COLOR_0"] = self.accessor(colors, "VEC4", ca["componentType"], ca.get("normalized", False))
        self.doc["meshes"].append(mesh)
        node = next(n for n in self.doc["nodes"] if n.get("name") == "Body")
        node.update(name="WardrobeBody", mesh=len(self.doc["meshes"]) - 1, skin=self.body_node["skin"])

    def add(self, name, slot, p, faces, j=None, w=None, normals=None):
        p = np.asarray(p, dtype=np.float32); faces = np.asarray(faces, dtype=np.uint32)
        if len(faces) == 0: return
        if j is None:
            ids = [self.kd.find(Vector(v))[1] for v in p]
            j, w = self.j[ids], self.w[ids]
        if normals is None:
            normals = np.zeros_like(p)
            fn = np.cross(p[faces[:, 1]] - p[faces[:, 0]], p[faces[:, 2]] - p[faces[:, 0]])
            for col in range(3): np.add.at(normals, faces[:, col], fn)
        normals = np.asarray(normals, dtype=np.float32)
        normals /= np.maximum(np.linalg.norm(normals, axis=1, keepdims=True), 1e-8)
        colors = np.zeros((len(p), 4), dtype=np.float32); colors[:, 0] = .92
        attrs = {"POSITION": self.accessor(p, "VEC3"), "NORMAL": self.accessor(normals, "VEC3"),
                 "TEXCOORD_0": self.accessor(p[:, :2], "VEC2"),
                 "COLOR_0": self.accessor(colors, "VEC4"), "JOINTS_0": self.accessor(j, "VEC4", 5123),
                 "WEIGHTS_0": self.accessor(w, "VEC4")}
        material = next(i for i, m in enumerate(self.doc["materials"]) if m["name"] == slot)
        self.doc["meshes"].append({"name": name, "primitives": [{"attributes": attrs, "indices": self.accessor(faces, "SCALAR", 5125), "material": material}]})
        self.doc["nodes"].append({"name": name, "mesh": len(self.doc["meshes"]) - 1, "skin": self.body_node["skin"]})
        self.doc["nodes"][self.parent]["children"].append(len(self.doc["nodes"]) - 1)

    def shell(self, name, slot, mask, offset, select=None, planes=(), limits=()):
        faces = self.faces[np.all(mask[self.faces], axis=1)]
        p = self.p + self.n * np.asarray(offset).reshape(-1, 1)
        if select is not None: faces = faces[select(p[faces].mean(axis=1))]
        if planes or limits:
            # Clip triangle edges and interpolate their skinning, rather than
            # selecting whole triangles: collars and cuffs need straight seams.
            verts=[]; normals=[]; joints=[]; weights=[]; triangles=[]
            full=np.zeros((len(self.p),len(self.names)))
            for col in range(4): full[np.arange(len(self.p)), self.j[:,col]] += self.w[:,col]
            for face in faces:
                polygon=[(p[i],self.n[i],full[i],np.array([p[i] @ normal+distance for normal,distance in planes]+[limit[i] for limit in limits])) for i in face]
                for field in range(len(planes)+len(limits)):
                    if not polygon: break
                    clipped=[]
                    for i, a in enumerate(polygon):
                        z=polygon[(i+1)%len(polygon)]
                        da=float(a[3][field]); dz=float(z[3][field])
                        if da>=0: clipped.append(a)
                        if (da>=0)!=(dz>=0):
                            t=da/(da-dz);clipped.append(tuple(a[k]+t*(z[k]-a[k]) for k in range(4)))
                    polygon=clipped
                start=len(verts)
                for pos,n,weights_all,_ in polygon:
                    ids=np.argsort(weights_all)[-4:][::-1];values=weights_all[ids];values/=values.sum()
                    verts.append(pos);normals.append(n);joints.append(ids);weights.append(values)
                for i in range(1,len(polygon)-1):triangles.append((start,start+i,start+i+1))
            self.add(name,slot,verts,triangles,joints,weights,normals)
        else:
            ids, inverse = np.unique(faces, return_inverse=True)
            self.add(name, slot, p[ids], inverse.reshape(-1, 3), self.j[ids], self.w[ids], self.n[ids])

    def write(self, path):
        self.doc["buffers"][0]["byteLength"] = len(self.data)
        raw = json.dumps(self.doc, separators=(",", ":")).encode()
        raw += b" " * ((-len(raw)) % 4); self.data.extend(b"\0" * ((-len(self.data)) % 4))
        total = 12 + 8 + len(raw) + 8 + len(self.data)
        with open(path, "wb") as out:
            out.write(struct.pack("<III", 0x46546C67, 2, total))
            out.write(struct.pack("<II", len(raw), 0x4E4F534A)); out.write(raw)
            out.write(struct.pack("<II", len(self.data), 0x004E4942)); out.write(self.data)


def gl(p): return np.array((p[0], p[2], -p[1]), dtype=np.float32)


def panel(b, name, slot, points):
    # A bevelled, closed patch: its visible face is held off the underlying shell.
    p = np.asarray(points, dtype=np.float32)
    n = np.cross(p[1] - p[0], p[2] - p[0]); n /= max(np.linalg.norm(n), 1e-7)
    if n[2] < 0: p = p[::-1]; n = -n
    q = np.concatenate((p, p - n * .002))
    faces = []
    for i in range(1, len(p) - 1): faces += [(0, i, i + 1), (len(p), len(p) + i + 1, len(p) + i)]
    for i in range(len(p)):
        j = (i + 1) % len(p); faces += [(i, len(p) + i, len(p) + j), (i, len(p) + j, j)]
    b.add(name, slot, q, faces)


def band(b, name, slot, center, axis, radius_a, radius_b, length, steps=24):
    axis = np.asarray(axis); axis /= np.linalg.norm(axis)
    right = np.cross(axis, np.array((0., 0., 1.)))
    if np.linalg.norm(right) < .1: right = np.cross(axis, np.array((0., 1., 0.)))
    right /= np.linalg.norm(right); front = np.cross(right, axis)
    p = []
    for t in (-.5, .5):
        for i in range(steps):
            angle = 2 * math.pi * i / steps
            p.append(center + axis * length * t + right * radius_a * math.sin(angle) + front * radius_b * math.cos(angle))
    faces = []
    for i in range(steps):
        j = (i + 1) % steps; faces += [(i, j, steps + j), (i, steps + j, steps + i)]
    b.add(name, slot, p, faces)


def build(variant, out):
    source = os.path.join(ROOT, "assets", "court_figures", "court_figure_" + variant + ".glb")
    b = Bundle(source); f = cf_body.Frame(cf_body.params(variant)); k = f.H / 1.72
    y = b.p[:, 1]
    weights = {}
    for family in ("hand", "thumb", "index", "fingers", "upper_arm", "forearm", "head", "neck"):
        ids = [i for i, n in enumerate(b.names) if n.split(".")[0] == family]
        weights[family] = np.sum(b.w * np.isin(b.j, ids), axis=1)
    arm = weights["upper_arm"] + weights["forearm"]
    hands = weights["hand"] + weights["thumb"] + weights["index"] + weights["fingers"]
    # Keep a generous source region, then clip seams through triangles. A
    # rectangular neck mask removed whole triangles and left shoulder tabs;
    # a hand-weight mask similarly left skin wedges behind the cuff.
    dress = (y < f.z_chin + .05 * k) & (hands < .995)
    sleeve_limits = []
    for side in ("L", "R"):
        wrist = gl(f.wrist[side]); axis = gl(f.wrist[side] - f.elbow[side]); axis /= np.linalg.norm(axis)
        on_arm = (arm + hands > .20) & (b.p[:, 0] * (1 if side == "L" else -1) > f.p["shoulder"] * .70)
        sleeve_limits.append(np.where(on_arm, -(b.p-wrist) @ axis-.002*k, 1.0))
    top = dress & ((y > f.z_hip - .030 * k) | (arm + hands > .45))
    legs = dress & (y < f.z_waist + .015 * k) & (arm + hands < .35)
    # Hide only vertices inside a complete cloth triangle, away from its boundary.
    cover = np.zeros(len(y), dtype=bool)
    coverage = dress & (y < f.z_shoulder+.025*k)
    for limit in sleeve_limits: coverage &= limit > .004*k
    covered_faces = b.faces[np.all(coverage[b.faces], axis=1)]
    cover[np.unique(covered_faces)] = True
    for _ in range(2):
        border_faces = b.faces[np.any(~cover[b.faces], axis=1)]
        cover[np.unique(border_faces)] = False
    b.body_copy(cover)

    # Front on an eased chest/waist envelope, respecting each body's stoop.
    sections = cf_body.torso_profile(f)
    def front(x, height, lift=.027):
        zs = [s[0] for s in sections]
        rx, fr, bk, cy = [float(np.interp(height, zs, [s[j] for s in sections])) for j in range(1, 5)]
        return (x, height, -cy + (fr + lift * k) * math.sqrt(max(.1, 1 - (x / (rx + .022 * k)) ** 2)))

    manifest = {}
    for kind in KINDS:
        before = len(b.doc["meshes"])
        ease = {"medieval": .018, "courtcoat": .026, "formal": .025, "business": .023}[kind] * k
        pant_ease = (.008 if kind == "medieval" else .015) * k
        # Individual leg topology remains separate at the crotch; no skirt weights
        # are borrowed for trousers, so sitting cannot pull one leg into the other.
        b.shell(kind + "_trousers", "CLOTH_A" if kind != "medieval" else "CLOTH_B", legs, np.full(len(y), pant_ease), planes=[(np.array((0,1,0)), -f.z_ankle-.008*k)])
        b.shell(kind + "_shoes", "LEATHER", legs, np.full(len(y), .013*k), planes=[(np.array((0,-1,0)), f.z_ankle+.052*k)])
        shirt_bottom = f.z_waist + (.04 if kind == "business" else -.035) * k
        eased=b.p+b.n*ease
        cuff_width=(.080 if kind=="courtcoat" else .038)*k
        tailored_sleeves=[]
        for side in ("L","R"):
            wrist=gl(f.wrist[side]);axis=gl(f.wrist[side]-f.elbow[side]);axis/=np.linalg.norm(axis)
            on_arm=(arm+hands>.20)&(b.p[:,0]*(1 if side=="L" else -1)>f.p["shoulder"]*.70)
            tailored_sleeves.append(np.where(on_arm,-(eased-wrist)@axis-.008*k-cuff_width,1.0))
        # Shoulders rise above the neck base in the source body. Restrict the
        # cut to the neck column, so a flat seam never slices their domes.
        neck_limit=np.maximum(f.z_shoulder+.050*k-eased[:,1],np.abs(eased[:,0])-.092*k)
        neck_trim=np.minimum(eased[:,1]-f.z_shoulder-k*(.030+.020*(eased[:,0]/(.091*k))**2),.091*k-np.abs(eased[:,0]))
        if kind == "medieval":
            b.shell(kind + "_doublet", "CLOTH_A", top, np.full(len(y), ease), limits=tailored_sleeves+[neck_limit,-neck_trim])
        else:
            b.shell(kind + "_jacket", "CLOTH_A", top, np.full(len(y), ease), limits=tailored_sleeves+[neck_limit,-neck_trim])
            slope=.072*k/(f.z_shoulder-shirt_bottom)
            planes=[(np.array((0,0,1)), -.025*k), (np.array((0,1,0)), -shirt_bottom),
                    (np.array((1,slope,0)), -slope*shirt_bottom), (np.array((-1,slope,0)), -slope*shirt_bottom),
                    (np.array((0,-1,0)), f.z_shoulder+.050*k)]
            b.shell(kind + "_shirt", "CLOTH_B", top, np.full(len(y), ease+.004*k), planes=planes, limits=[neck_limit])
        # Medieval surcoat and early-modern skirts/tails are real open panels.
        # Splits allow the two thighs to articulate independently when seated.
        if kind != "business":
            length = {"medieval": .25, "courtcoat": .28, "formal": .13}[kind] * k
            hem = f.z_hip - length
            # Side seams are continuous: the previous four quarter panels left
            # full-height rectangular side gaps as soon as either thigh moved.
            # Only front/back vents separate the legs; coat tails stay open at
            # the front. The waist follows the existing torso, without a shelf.
            sectors = ((-math.pi+.025,-.025),(.025,math.pi-.025))
            if kind=="courtcoat":sectors=((-math.pi+.025,-.5*math.pi),(.5*math.pi,math.pi-.025))
            for side_i, (a0, a1) in enumerate(sectors):
                verts = []; joints = []; values = []; anchors = []
                rings, steps = 12, 19
                for row in range(rings):
                    t = row / (rings - 1)
                    height = f.z_hip + .08 * k - t * (length + .08 * k)
                    section_height=max(height,f.z_hip)
                    rx,fr,bk,cy=[float(np.interp(section_height,[s[0] for s in sections],[s[j] for s in sections])) for j in range(1,5)]
                    # The delivered body includes the rounded union with the
                    # thighs; its actual hip is wider than the trunk blueprint.
                    row_body=b.p[(np.abs(y-section_height)<.012*k)&(arm+hands<.2)]
                    if len(row_body):rx=max(rx,float(np.max(np.abs(row_body[:,0]))))
                    for col in range(steps):
                        a = a0 + (a1 - a0) * col / (steps - 1)
                        # Around +Z front; a narrow centre opening is deliberate.
                        x = math.sin(a) * (rx+ease+.004*k+.018*k*t)
                        depth=fr if math.cos(a)>=0 else bk
                        clearance=(depth+ease+.004*k)*(1-min(1,t/.28))+(.155+.025*t)*k*min(1,t/.28)
                        z = -cy+math.cos(a)*clearance
                        verts.append((x, height, z))
                        joint = b.names.index("thigh." + ("L" if x >= 0 else "R"))
                        if row==0:
                            nearest=b.kd.find(Vector((x,height,z)))[1]
                            anchor=np.zeros(len(b.names))
                            for index,value in zip(b.j[nearest],b.w[nearest]):anchor[index]+=value
                            anchors.append(anchor)
                        # Front fabric must follow the raised thigh promptly.
                        # Behind the seat, spread the hip/thigh bend over more
                        # cloth instead of pulling one short row apart by 7cm.
                        transition=.42+.38*max(0.0,-math.cos(a))
                        bend = min(1.0, t / transition)
                        follow = bend * bend * (3.0 - 2.0 * bend)
                        # The upper hem belongs to the actual waist, whose
                        # weights can include spine as well as hips. A generic
                        # hips-only ring separated from a leaning doublet.
                        weight=anchors[col]*(1-follow);weight[joint]+=follow
                        ids=np.argsort(weight)[-4:][::-1];kept=weight[ids];kept/=kept.sum()
                        joints.append(ids);values.append(kept)
                faces = []
                for row in range(rings - 1):
                    for col in range(steps - 1):
                        i = row * steps + col; faces += [(i, i + steps, i + steps + 1), (i, i + steps + 1, i + 1)]
                b.add(kind + "_skirt_" + str(side_i), "CLOTH_A", verts, faces, joints, values)
        # Contrasting cuffs and an upright collar make the tailoring readable at
        # court camera distance. Children have smaller, plain collars and no tie.
        for side in ("L", "R"):
            wrist = gl(f.wrist[side]); axis = gl(f.wrist[side] - f.elbow[side]); axis /= np.linalg.norm(axis)
            width=cuff_width
            cuff_mask=(arm+hands>.15) & (b.p[:,0]*(1 if side=="L" else -1)>0)
            b.shell(kind + "_cuff_" + side, "CLOTH_C" if kind in ("medieval", "courtcoat") else "CLOTH_B",
                    cuff_mask, np.full(len(y),ease),
                    planes=[(axis,-float(wrist@axis)+.008*k+width),(-axis,float(wrist@axis)-.008*k)])
        # This collar is sewn into the shell: matching clipping fields and
        # identical interpolated skinning leave no overlapping independent
        # rings to fold through one another during seated speech.
        b.shell(kind+"_collar","CLOTH_C" if kind=="medieval" else "CLOTH_B",
                top,np.full(len(y),ease),limits=[neck_limit,neck_trim])
        if kind == "medieval":
            # Follow the delivered waist and its skinning, including stooped
            # bodies. A two-ring fixed oval floated behind a seated torso.
            belt_mask=top & (arm+hands<.20)
            b.shell(kind+"_belt","LEATHER",belt_mask,np.full(len(y),ease+.003*k),
                    planes=[(np.array((0,1,0)),-f.z_waist+.019*k),
                            (np.array((0,-1,0)),f.z_waist+.019*k)])
            for i in range(4):
                h = f.z_chest + .05 * k - i * .038 * k
                panel(b, kind + "_lacing_" + str(i), "CLOTH_C", [front(-.025*k,h+.006*k,.031), front(.025*k,h-.008*k,.031), front(.025*k,h-.015*k,.031), front(-.025*k,h-.001*k,.031)])
        else:
            for side in (-1, 1):
                low = f.z_waist + (.03 if kind == "business" else -.015) * k
                panel(b, kind + "_lapel_" + str(side), "CLOTH_A" if kind == "business" else "CLOTH_C",
                      [front(side*.065*k,f.z_shoulder-.023*k,.043), front(side*.12*k,f.z_chest+.036*k,.043),
                       front(side*.043*k,low,.043), front(side*.025*k,f.z_chest-.01*k,.043)])
            if not f.p.get("child"):
                if kind == "business":
                    panel(b, kind + "_tie", "CLOTH_C", [front(-.014*k,f.z_shoulder-.033*k,.048),front(.014*k,f.z_shoulder-.033*k,.048),front(.022*k,f.z_waist+.09*k,.048),front(0,f.z_waist+.06*k,.048),front(-.022*k,f.z_waist+.09*k,.048)])
                else:
                    panel(b, kind + "_cravat", "CLOTH_B", [front(-.041*k,f.z_shoulder-.014*k,.05),front(.041*k,f.z_shoulder-.014*k,.05),front(.027*k,f.z_chest+.002*k,.05),front(-.027*k,f.z_chest+.002*k,.05)])
            count = 6 if kind == "courtcoat" else (4 if kind == "formal" else 2)
            for i in range(count):
                h = f.z_waist + .025*k + i*.039*k
                x = .042*k if kind == "courtcoat" else .021*k
                panel(b, kind + "_button_" + str(i), "CLOTH_C", [front(x-.006*k,h-.006*k,.051),front(x+.006*k,h-.006*k,.051),front(x+.006*k,h+.006*k,.051),front(x-.006*k,h+.006*k,.051)])
        manifest[kind] = [m["name"] for m in b.doc["meshes"][before:]]
    path = os.path.join(out, "court_wardrobe_" + variant + ".glb")
    b.write(path)
    record = {"variant": variant, "source_sha256": hashlib.sha256(open(source,"rb").read()).hexdigest(),
              "file": os.path.basename(path), "outfits": manifest, "covered_vertices": int(cover.sum()),
              "body_vertices": len(y), "sha256": hashlib.sha256(open(path,"rb").read()).hexdigest()}
    print("COURT_WARDROBE", variant, len(b.doc["meshes"]), "meshes", len(b.data), "bytes", flush=True)
    return record


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--variants", default=",".join(cf_body.VARIANTS))
    parser.add_argument("--out", default=os.path.join(ROOT,"assets","court_figures","wardrobe"))
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    os.makedirs(args.out, exist_ok=True)
    variants = [build(v, args.out) for v in args.variants.split(",")]
    with open(os.path.join(args.out,"court_wardrobe.json"),"w") as out:
        json.dump({"version":1,"outfits":list(KINDS),"cover_channel":1,"variants":variants},out,indent=2)
