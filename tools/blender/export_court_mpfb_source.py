"""Export native MPFB heads for the court adapter, without editing game GLBs.

Run with the user's installed/enabled MPFB (do not use --factory-startup):
  blender --background --python-exit-code 2 --python this_file -- --variant all

NPZ coordinates are X subject-left, Y up, Z forward, in metres of a .282 m
head. Geometry is uniformly scaled; shader landmarks do not deform anatomy.
Only the final NPZ/provenance/license files are written. No pickle is needed.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib
import json
from collections import Counter, defaultdict
from pathlib import Path
import sys

import bpy
import numpy as np

VARIANTS = {
    "male_adult": (1.0, .45), "female_adult": (0.0, .45),
    "male_old": (1.0, .82), "female_old": (0.0, .82),
    "male_young": (1.0, .27), "female_young": (0.0, .27),
    "child": (.5, .14),
}
IDENTITIES = ("jaw", "chin", "cheek", "nose", "bridge", "nose_wide", "brow",
              "lips", "ears", "long", "round", "aged")
EXPRESSIONS = ("smile", "frown", "brows_up", "brows_down", "brows_worried",
               "eyes_wide", "eyes_narrow", "blink", "jaw_open", "lips_pressed",
               "sneer", "cheeks_puff", "v_aa", "v_ee", "v_oo", "v_mm", "v_fv")
MOODS = ("mood_smile", "mood_tight", "mood_worry", "mood_stern")
NAMES = tuple("face_" + n for n in IDENTITIES) + EXPRESSIONS + MOODS

# A signed identity delta is the midpoint slope between native opposed targets.
# Its modest amplitude permits the court's existing [-1,+1] identity weights.
# Entries without an opposed target use a small one-sided native displacement.
IDENTITY_TARGETS = {
    "jaw": [("chin/chin-width", .32), ("head/head-square", .12)],
    "chin": [("chin/chin-prominent", .32), ("chin/chin-height", .10)],
    "cheek": [(s + "-cheek-bones", .20) for s in ("cheek/l", "cheek/r")]
             + [(s + "-cheek-volume", .18) for s in ("cheek/l", "cheek/r")],
    "nose": [("nose/nose-scale-depth", .20), ("nose/nose-scale-vert", .08)],
    "bridge": [("nose/nose-hump", .20), ("nose/nose-greek", .12)],
    "nose_wide": [("nose/nose-scale-horiz", .22), ("nose/nose-width3", .10)],
    "brow": [("eyebrows/eyebrows-trans", .24, "backward", "forward"),
             ("forehead/forehead-nubian", .10)],
    "lips": [("mouth/mouth-upperlip-volume", .23), ("mouth/mouth-lowerlip-volume", .23),
             ("mouth/mouth-upperlip-height", .08), ("mouth/mouth-lowerlip-height", .08)],
    "ears": [("ears/l-ear-scale", .18), ("ears/r-ear-scale", .18)],
    "long": [("head/head-scale-vert", .16)],
    "round": [("head/head-round", .18), ("head/head-fat", .10)],
    "aged": [("head/head-age", .22)],
}

# Bilateral units add, because each one moves its own side. Averaging would
# halve the blink and leave eyes open. Gaze keys intentionally stay off Body.
COMPOSITES = {
    "smile": {"mouthSmileLeft": .70, "mouthSmileRight": .70,
              "cheekSquintLeft": .10, "cheekSquintRight": .10},
    "frown": {"mouthFrownLeft": .70, "mouthFrownRight": .70},
    "brows_up": {"browInnerUp": .65, "browOuterUpLeft": .65, "browOuterUpRight": .65},
    "brows_down": {"browDownLeft": .70, "browDownRight": .70},
    "brows_worried": {"browInnerUp": .75, "browDownLeft": .12, "browDownRight": .12},
    "eyes_wide": {"eyeWideLeft": .65, "eyeWideRight": .65},
    "eyes_narrow": {"eyeSquintLeft": .65, "eyeSquintRight": .65},
    "blink": {"eyeBlinkLeft": 1.0, "eyeBlinkRight": 1.0},
    "jaw_open": {"jawOpen": .70},
    "lips_pressed": {"mouthPressLeft": .75, "mouthPressRight": .75},
    "sneer": {"noseSneerRight": .65, "mouthUpperUpRight": .25,
              "noseSneerLeft": .15, "mouthUpperUpLeft": .06},
    "cheeks_puff": {"cheekPuff": .65},
    "v_aa": {"viseme_aa": .75}, "v_ee": {"viseme_I": .80},
    "v_oo": {"viseme_U": .80}, "v_mm": {"viseme_PP": 1.0},
    "v_fv": {"viseme_FF": .85},
}
for mood, expression in zip(MOODS, ("smile", "lips_pressed", "brows_worried", "brows_down")):
    COMPOSITES[mood] = dict(COMPOSITES[expression])

SOURCE_LINKS = {
    "mpfb": "https://extensions.blender.org/add-ons/mpfb/",
    "mpfb_license": "https://github.com/makehumancommunity/mpfb2/blob/master/LICENSE.md",
    "system_assets": "https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html",
    "faceunits01": "https://static.makehumancommunity.org/assets/assetpacks/faceunits01.html",
    "visemes02": "https://static.makehumancommunity.org/assets/assetpacks/visemes02.html",
    "expression_license": "https://github.com/makehumancommunity/extra-targets/blob/main/LICENSE",
}


def coords(data):
    result = np.empty((len(data), 3), np.float32)
    data.foreach_get("co", result.ravel())
    return result


def group_indices(obj, name):
    group = obj.vertex_groups.get(name)
    if group is None:
        raise ValueError("Missing MPFB landmark group: " + name)
    return np.array([v.index for v in obj.data.vertices
                     if any(g.group == group.index for g in v.groups)], dtype=np.uint32)


def converted(vectors):
    # Blender X/-Y/Z -> glTF X/Y/Z. Determinant +1: retain source winding.
    return np.asarray(vectors)[..., [0, 2, 1]] * np.array([1, 1, -1], np.float32)


def triangulate(obj):
    obj.data.calc_loop_triangles()
    triangles = np.asarray([t.vertices[:] for t in obj.data.loop_triangles], dtype=np.uint32)
    if obj.data.uv_layers:
        uv = obj.data.uv_layers[0].data
        loops = np.asarray([[uv[i].uv[:] for i in t.loops] for t in obj.data.loop_triangles], np.float32)
    else:
        loops = np.zeros((len(triangles), 3, 2), np.float32)
    return triangles, loops


def boundary_loops(triangles):
    counts = Counter(tuple(sorted((int(a), int(b)))) for t in triangles
                     for a, b in zip(t, np.roll(t, -1)))
    adjacent = defaultdict(list)
    for (a, b), count in counts.items():
        if count == 1:
            adjacent[a].append(b)
            adjacent[b].append(a)
        if count > 2:
            raise ValueError("Non-manifold source edge")
    if any(len(n) != 2 for n in adjacent.values()):
        raise ValueError("Cut produced a branching boundary")
    todo, loops = set(adjacent), []
    while todo:
        start = min(todo)
        loop, previous, current = [], -1, start
        while current not in loop:
            loop.append(current)
            todo.discard(current)
            nxt = next(n for n in adjacent[current] if n != previous)
            previous, current = current, nxt
        if current != start:
            raise ValueError("Boundary is not a simple closed loop")
        loops.append(loop)
    return loops


def source_services():
    module = next((a for a in bpy.context.preferences.addons.keys()
                   if a.endswith(".mpfb") or a == "mpfb"), None)
    if module is None:
        raise RuntimeError("Enable the installed MPFB extension before running this exporter")
    def service(name, cls):
        return getattr(importlib.import_module(module + ".services." + name), cls)
    return {
        "module": module, "extension": importlib.import_module(module),
        "Human": service("humanservice", "HumanService"),
        "Target": service("targetservice", "TargetService"),
        "Face": service("faceservice", "FaceService"),
        "Location": service("locationservice", "LocationService"),
        "Mhclo": getattr(importlib.import_module(module + ".entities.clothes.mhclo"), "Mhclo"),
    }


def interpolate(deltas, child, mhclo_path, services):
    """MPFB's native MHCLO barycentric fitting, including identity targets.

    FaceService only transfers its known facial names. Applying the same
    correspondence here also carries our composite identity deltas to brows,
    teeth and eye centres; small valid deltas are not thresholded away.
    """
    mapping = services["Mhclo"]()
    mapping.load(str(mhclo_path))
    result = np.zeros((len(deltas), len(child.data.vertices), 3), np.float32)
    for i, correspondence in mapping.verts.items():
        if i >= result.shape[1]:
            continue
        ids = correspondence["verts"]
        weights = np.asarray(correspondence["weights"], np.float32)
        result[:, i] = (deltas[:, ids] * weights[None, :, None]).sum(axis=1)
    return result


def export_variant(variant, output, services):
    H, T, F = services["Human"], services["Target"], services["Face"]
    extension = Path(services["extension"].__file__).parent
    system = extension / "data"
    user = Path(services["Location"].get_user_data())
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    macro = T.get_default_macro_info_dict()
    macro.update(gender=VARIANTS[variant][0], age=VARIANTS[variant][1])
    macro["race"] = {k: 1.0 / 3.0 for k in macro["race"]}
    human = H.create_human(macro_detail_dict=macro, mask_helpers=False)
    T.bake_targets(human)
    base = coords(human.data.vertices)
    group_table = json.loads((system / "mesh_metadata/basemesh_vertex_groups.json").read_text())
    surface_count = min(a for a, b in group_table["HelperGeometry"])
    assert surface_count == 13380, "Review landmark indices if MPFB's base topology changes"
    eye_indices = [group_indices(human, "joint-l-eye"), group_indices(human, "joint-r-eye")]
    eye_source = np.asarray([base[ids].mean(axis=0) for ids in eye_indices])
    # Vertex 991 is the chin landmark used by MPFB's default jaw/special04 rig.
    # Actual scalp maximum is preferable to the head-2 helper above the scalp.
    chin = base[991].copy()
    top_index = int(np.argmax(base[:surface_count, 2]))
    height = float(base[top_index, 2] - chin[2])
    assert .12 < height < .40, (variant, height)
    scale = .282 / height
    origin = np.array([0.0, chin[2], -eye_source[:, 1].mean() - .085 / scale], np.float32)
    normalize = lambda v: ((converted(v) - origin) * scale).astype(np.float32)
    whole = normalize(base)

    # Preserve native surface topology and keep all mouth/nostril lining.
    all_triangles, all_uv = triangulate(human)
    keep = (all_triangles < surface_count).all(axis=1)
    keep &= (whole[all_triangles, 1] >= -.045).all(axis=1)
    selected = all_triangles[keep]
    indices = np.unique(selected).astype(np.uint32)
    remap = np.full(len(base), -1, np.int32)
    remap[indices] = np.arange(len(indices))
    triangles = remap[selected].astype(np.uint32)
    positions = whole[indices]
    loops = boundary_loops(triangles)
    neck_loops = [loop for loop in loops if positions[loop, 1].max() < .005]
    assert len(neck_loops) == 1, (variant, "expected one neck boundary", [len(l) for l in neck_loops])
    neck_boundary = np.asarray(neck_loops[0], np.uint32)

    native_cache = {}
    input_hashes = {"3dobjs/base.obj": hashlib.sha256((system / "3dobjs/base.obj").read_bytes()).hexdigest()}
    def native(fragment):
        if fragment in native_cache:
            return native_cache[fragment]
        path = system / "targets" / (fragment + ".target.gz")
        key = T.load_target(human, str(path), name="native_" + fragment.replace("/", "_"))
        native_cache[fragment] = coords(key.data) - base
        input_hashes["targets/" + fragment + ".target.gz"] = hashlib.sha256(path.read_bytes()).hexdigest()
        return native_cache[fragment]

    deltas = np.zeros((len(NAMES), len(base), 3), np.float32)
    identity_scales = {}
    for i, name in enumerate(IDENTITIES):
        for entry in IDENTITY_TARGETS[name]:
            fragment, amplitude = entry[:2]
            low, high = entry[2:] if len(entry) == 4 else ("decr", "incr")
            if (system / "targets" / (fragment + ".target.gz")).exists():
                slope = native(fragment)
            else:
                slope = (native(fragment + "-" + high) - native(fragment + "-" + low)) * .5
            deltas[i] += slope * amplitude
        peak = float(np.linalg.norm(deltas[i, indices], axis=1).max() * scale)
        limit = .009 if variant == "child" else .012
        gain = min(1.0, limit / max(peak, 1e-12))
        deltas[i] *= gain
        identity_scales[name] = gain
    F.load_targets(human, load_microsoft_visemes=False, load_meta_visemes=True, load_arkit_faceunits=True)
    used_units = set(n for composite in COMPOSITES.values() for n in composite)
    for path in (user / "targets").rglob("*.target"):
        if path.stem in used_units:
            input_hashes[str(path.relative_to(user)).replace("\\", "/")] = hashlib.sha256(path.read_bytes()).hexdigest()
    for i, name in enumerate(NAMES[len(IDENTITIES):], len(IDENTITIES)):
        for source_name, weight in COMPOSITES[name].items():
            deltas[i] += (coords(human.data.shape_keys.key_blocks[source_name].data) - base) * weight

    assets = {}
    for kind, rel, asset_type in (
        ("brow", "eyebrows/eyebrow001/eyebrow001.mhclo", "Eyebrows"),
        ("teeth", "teeth/teeth_base/teeth_base.mhclo", "Teeth"),
        ("eye", "eyes/low-poly/low-poly.mhclo", "Eyes"),
    ):
        path = user / rel
        obj = H.add_mhclo_asset(str(path), human, asset_type=asset_type,
                               subdiv_levels=0, material_type="MAKESKIN")
        assets[kind] = (obj, path)
        input_hashes[rel] = hashlib.sha256(path.read_bytes()).hexdigest()
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.startswith("obj_file "):
                mesh_path = path.parent / line.split(maxsplit=1)[1]
                input_hashes[str(mesh_path.relative_to(user)).replace("\\", "/")] = hashlib.sha256(mesh_path.read_bytes()).hexdigest()

    triangle_uv = all_uv[keep]
    uv = np.zeros((len(indices), 2), np.float32)
    for tri, tuv in zip(triangles, triangle_uv):
        uv[tri] = tuv
    result = {
        "positions": positions, "triangles": triangles, "source_indices": indices,
        "uv": uv, "triangle_uv": triangle_uv, "names": np.asarray(NAMES),
        "deltas": (converted(deltas[:, indices]) * scale).astype(np.float32),
        "neck_boundary": neck_boundary,
        "eye_centers": normalize(eye_source),
        "eye_center_deltas": (converted(np.asarray([deltas[:, ids].mean(axis=1) for ids in eye_indices]).transpose(1, 0, 2)) * scale).astype(np.float32),
    }
    for kind in ("brow", "teeth"):
        obj, path = assets[kind]
        t, tuv = triangulate(obj)
        result[kind + "_positions"] = normalize(coords(obj.data.vertices))
        result[kind + "_triangles"] = t
        result[kind + "_deltas"] = (converted(interpolate(deltas, obj, path, services)) * scale).astype(np.float32)
        result[kind + "_triangle_uv"] = tuv

    eye_positions = normalize(coords(assets["eye"][0].data.vertices))
    eye_radii = []
    for i, side in enumerate((1, -1)):
        verts = eye_positions[eye_positions[:, 0] * side > 0]
        # Robust axes about the native eye joint, covering the fitted sphere.
        eye_radii.append(np.max(np.abs(verts - result["eye_centers"][i]), axis=0))
    result["eye_radii"] = np.asarray(eye_radii, np.float32)

    brow_co = result["brow_positions"]
    mouth = normalize((base[493] + base[474]) * .5)
    nose = normalize(base[343])
    corners = normalize(base[[10407, 3739]])
    landmarks = {
        "chin": normalize(chin).tolist(), "top": normalize(base[top_index]).tolist(),
        "mouth_seam": mouth.tolist(), "nose_base": nose.tolist(),
        "mouth_corners": corners.tolist(), "lip_width": float(abs(corners[0, 0] - corners[1, 0])),
        "eyes": result["eye_centers"].tolist(),
        "brows": [brow_co[brow_co[:, 0] * side > 0].mean(axis=0).tolist() for side in (1, -1)],
        "source_vertex_indices": {"chin": 991, "top": top_index, "mouth_seam": [493, 474],
                                  "nose_base": 343, "mouth_corners": [10407, 3739]},
    }
    metadata = {
        "schema": 1, "variant": variant, "coordinates": "X subject-left; Y up; Z forward; metres",
        "normalized_head_height": .282, "source_head_height": height,
        "source_origin_gltf": origin.tolist(), "uniform_scale": scale,
        "source_surface_vertex_count": surface_count, "macro": macro,
        "cut": {"minimum_vertex_y": -.045, "neck_boundary_count": len(neck_boundary),
                "boundary_loop_sizes": [len(l) for l in loops], "no_caps": True},
        "landmarks": landmarks, "identity_gain_limits": identity_scales,
        "paint_y_anchors": [[0.0, 0.0], [float(mouth[1]), .054], [float(nose[1]), .089],
                            [float(result["eye_centers"][:, 1].mean()), .133],
                            [float(brow_co[:, 1].mean()), .160], [.282, .282]],
        "identity_range": [-1, 1], "expression_range": [0, 1],
        "uv": "Native Blender UV; uv retains one corner per vertex; triangle_uv preserves seams exactly",
        "winding": "CCW source winding; axis conversion is a proper rotation",
        "blender_version": bpy.app.version_string,
        "mpfb_version": list(services["extension"].VERSION),
        "mpfb_build": services["extension"].BUILD_INFO,
        "sources": SOURCE_LINKS, "input_sha256": input_hashes,
        "brow_asset": "eyebrow001", "teeth_asset": "teeth_base", "license": "CC0-1.0",
    }
    result["metadata"] = np.asarray(json.dumps(metadata, sort_keys=True))
    validate(result)
    dest = output / (variant + ".npz")
    temporary = dest.with_suffix(".tmp.npz")
    np.savez_compressed(temporary, **result)
    temporary.replace(dest)
    with np.load(dest, allow_pickle=False) as saved:
        validate(saved)
    summary = {"variant": variant, "vertices": len(positions), "triangles": len(triangles),
               "brow_triangles": len(result["brow_triangles"]), "teeth_triangles": len(result["teeth_triangles"]),
               "shapes": len(NAMES), "neck_boundary": len(neck_boundary),
               "sha256": hashlib.sha256(dest.read_bytes()).hexdigest(), "bytes": dest.stat().st_size}
    print("MPFB_SOURCE=" + json.dumps(summary), flush=True)
    return summary


def validate(data):
    assert tuple(data["names"].tolist()) == NAMES
    for prefix in ("", "brow_", "teeth_"):
        p, t, d = (data[prefix + k] for k in ("positions", "triangles", "deltas"))
        assert p.ndim == 2 and p.shape[1] == 3 and len(p)
        assert t.ndim == 2 and t.shape[1] == 3 and len(t)
        assert int(t.max()) < len(p)
        assert d.shape == (len(NAMES), len(p), 3)
        assert np.isfinite(p).all() and np.isfinite(d).all()
        area = np.linalg.norm(np.cross(p[t[:, 1]] - p[t[:, 0]], p[t[:, 2]] - p[t[:, 0]]), axis=1)
        assert (area > 1e-12).all(), (prefix, "degenerate triangles")
    assert np.isclose(data["positions"][:, 1].max(), .282, atol=1e-6)
    assert data["eye_centers"][0, 0] > 0 > data["eye_centers"][1, 0]
    assert np.all((data["eye_radii"] > .003) & (data["eye_radii"] < .035))
    for key in NAMES:
        index = NAMES.index(key)
        assert np.linalg.norm(data["deltas"][index], axis=1).max() > 1e-6, key
    # These prove native correspondence carried real expressions onto both
    # accessories; merely exporting same-size arrays would miss a failed fit.
    assert np.linalg.norm(data["brow_deltas"][NAMES.index("brows_up")], axis=1).max() > .001
    assert np.linalg.norm(data["teeth_deltas"][NAMES.index("jaw_open")], axis=1).max() > .005
    assert len(np.unique(data["source_indices"])) == len(data["positions"])
    # The runtime extrapolates each identity in both directions. A conservative
    # native recipe must keep triangle orientation at both signed endpoints.
    p, t = data["positions"], data["triangles"]
    rest = np.cross(p[t[:, 1]] - p[t[:, 0]], p[t[:, 2]] - p[t[:, 0]])
    for i, name in enumerate(IDENTITIES):
        for sign in (-1, 1):
            moved = p + sign * data["deltas"][i]
            normal = np.cross(moved[t[:, 1]] - moved[t[:, 0]], moved[t[:, 2]] - moved[t[:, 0]])
            assert ((rest * normal).sum(axis=1) > 0).all(), (name, sign, "identity folds a triangle")
    boundary = data["neck_boundary"]
    assert len(boundary) >= 8 and len(np.unique(boundary)) == len(boundary)
    assert data["positions"][boundary, 1].max() < .005


def copy_source_textures(output, services):
    """Preserve native brow alpha and the enamel/gum color distinction."""
    user = Path(services["Location"].get_user_data())
    textures = {}
    for relative, usage in (
        ("eyebrows/eyebrow001/eyebrow001.png",
         "Native eyebrow001 diffuse/alpha; retain brow_triangle_uv and alpha-test edges"),
        ("teeth/teeth_base/teeth.png",
         "Native teeth_base diffuse; retain teeth_triangle_uv seams to distinguish enamel and gums"),
    ):
        source = user / relative
        material = source.with_suffix(".mhmat")
        content = source.read_bytes()
        destination = output / source.name
        destination.write_bytes(content)
        digest = hashlib.sha256(content).hexdigest()
        assert hashlib.sha256(destination.read_bytes()).hexdigest() == digest
        textures[source.name] = {
            "sha256": digest, "source_path": relative, "license": "CC0-1.0", "usage": usage,
            "input_sha256": {
                relative: digest,
                str(material.relative_to(user)).replace("\\", "/"): hashlib.sha256(material.read_bytes()).hexdigest(),
            },
        }
    return textures


def main():
    if not bpy.app.background:
        raise RuntimeError("Run in a fresh background Blender process; never in an interactive scene")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--variant", choices=("all", *VARIANTS), default="all")
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[2] / "assets/court_figures/mpfb_source")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    args.output.mkdir(parents=True, exist_ok=True)
    services = source_services()
    requested = VARIANTS if args.variant == "all" else [args.variant]
    for variant in requested:
        export_variant(variant, args.output, services)
    files = {}
    for path in sorted(args.output.glob("*.npz")):
        with np.load(path, allow_pickle=False) as data:
            validate(data)
            files[path.name] = {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                                "vertices": len(data["positions"]), "triangles": len(data["triangles"]),
                                "metadata": json.loads(str(data["metadata"]))}
    provenance = {"schema": 1, "license": "CC0-1.0", "sources": SOURCE_LINKS,
                  "textures": copy_source_textures(args.output, services),
                  "identity_targets": IDENTITY_TARGETS, "expression_composites": COMPOSITES, "files": files}
    (args.output / "provenance.json").write_text(json.dumps(provenance, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (args.output / "LICENSE.md").write_text(
        "# Native MPFB court source assets\n\n"
        "The NPZ geometry and deformation data, and the original eyebrow001.png and teeth.png textures, derive from MakeHuman/MPFB's "
        "CC0 graphical assets and the CC0 faceunits01/visemes02 targets. The generated asset data "
        "and any adaptation of it in this directory are provided under CC0 1.0 Universal.\n\n"
        "License: https://creativecommons.org/publicdomain/zero/1.0/\n\n"
        "MPFB's software license is separate from its graphical assets. See "
        + SOURCE_LINKS["mpfb_license"] + " and " + SOURCE_LINKS["expression_license"] + ".\n\n"
        "MakeHuman system meshes credit Data Collection AB, Joel Palmius and Jonas Hauquier. "
        "The facial-unit/viseme packs credit Mika Suominen. Exact source links, versions, "
        "target recipes and per-file hashes are recorded in provenance.json.\n",
        encoding="utf-8")


if __name__ == "__main__":
    main()
