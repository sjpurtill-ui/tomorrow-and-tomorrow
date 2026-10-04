"""Audit sculpted court GLBs against an immutable Git baseline.

Run from any directory with Python and NumPy.  This validator reads source and
assets only; it does not import the sculptor, regenerate files, or trust its
reported preservation counts.
"""
import argparse
from collections import Counter
import copy
import json
from pathlib import Path
import struct
import subprocess
import sys

import numpy as np
from validate_court_wardrobe import GLB


VARIANTS = ("male_adult", "female_adult", "male_old", "female_old",
            "male_young", "female_young", "child")
BUNDLES = (("", "figure", "Body"), ("legacy/", "legacy", "LegacyBody"),
           ("wardrobe/", "wardrobe", "WardrobeBody"))


class Blob(GLB):
    """Use the existing independent accessor reader on an in-memory GLB."""
    def __init__(self, raw):
        self.raw = raw
        assert len(raw) >= 28, "truncated GLB"
        magic, version, total = struct.unpack_from("<III", raw)
        assert magic == 0x46546C67 and version == 2 and total == len(raw), "invalid GLB header"
        chunks = []
        offset = 12
        while offset < len(raw):
            size, kind = struct.unpack_from("<II", raw, offset)
            assert size % 4 == 0 and offset + 8 + size <= len(raw), "invalid GLB chunk"
            chunks.append((kind, raw[offset + 8:offset + 8 + size]))
            offset += 8 + size
        assert len(chunks) == 2 and chunks[0][0] == 0x4E4F534A and chunks[1][0] == 0x004E4942, "expected JSON and BIN chunks"
        self.doc = json.loads(chunks[0][1])
        self.bin = chunks[1][1]
        assert len(self.doc["buffers"]) == 1 and "uri" not in self.doc["buffers"][0], "external buffer"
        assert self.doc["buffers"][0]["byteLength"] <= len(self.bin), "buffer length exceeds BIN chunk"


def _different_path(before, after, path="document"):
    if type(before) is not type(after):
        return path
    if isinstance(before, dict):
        if before.keys() != after.keys():
            return path + " keys"
        for key in before:
            if before[key] != after[key]:
                return _different_path(before[key], after[key], path + "." + key)
    elif isinstance(before, list):
        if len(before) != len(after):
            return path + " length"
        for i, (a, b) in enumerate(zip(before, after)):
            if a != b:
                return _different_path(a, b, path + "[%d]" % i)
    return path


def check_preservation(before, after, body):
    assert after.bin[:len(before.bin)] == before.bin, "original binary payload changed (rig/animation/garment preservation failed)"
    original = before.doc
    current = copy.deepcopy(after.doc)
    for key in ("accessors", "bufferViews"):
        count = len(original[key])
        assert len(current[key]) > count, "no appended " + key
        assert current[key][:count] == original[key], "original " + key + " changed"
        current[key] = current[key][:count]
    # Only the one existing Body primitive is permitted to use replacement
    # arrays. Every other node, mesh, material, skin and animation is exact.
    node = next(n for n in original["nodes"] if n.get("name") == body)
    index = node["mesh"]
    old_mesh = original["meshes"][index]
    new_mesh = current["meshes"][index]
    assert len(old_mesh["primitives"]) == len(new_mesh["primitives"]) == 1, "body primitive count changed"
    old, new = old_mesh["primitives"][0], new_mesh["primitives"][0]
    assert old["attributes"].keys() == new["attributes"].keys(), "body attribute names changed"
    assert len(new["targets"]) == len(old["targets"]) == 20, "expected twenty preserved morph targets"
    for a, b in zip(old["targets"], new["targets"]):
        assert a.keys() == b.keys(), "morph channels changed"
    references = [new["indices"], *new["attributes"].values()]
    references += [value for target in new["targets"] for value in target.values()]
    assert all(i >= len(original["accessors"]) for i in references), "replacement body uses an old accessor"
    assert len(set(references)) == len(references), "replacement arrays unexpectedly alias"
    for key in ("indices", "attributes", "targets"):
        new[key] = old[key]
    assert new_mesh.get("extras", {}).pop("anatomy_revision", None) == 1, "missing anatomy revision"
    current["buffers"][0]["byteLength"] = original["buffers"][0]["byteLength"]
    assert current == original, "unexpected metadata change: " + _different_path(original, current)


def _frame(glb, primitive, variant):
    # UV0 is the delivered face-space projection. Use the unchanged baseline
    # to infer physical scale and chin; no sculptor functions are imported.
    points = glb.values(primitive["attributes"]["POSITION"]).astype(np.float64)
    uv = glb.values(primitive["attributes"]["TEXCOORD_0"]).astype(np.float64)
    valid = np.abs(uv[:, 0]) > .01
    scale = float(np.median(points[valid, 0] / uv[valid, 0]))
    chin = float(np.median(points[:, 1] - (1. - uv[:, 1]) * scale))
    assert .6 < scale < 1.1, "implausible head scale"
    return scale, np.array([0., chin, .020 if variant.endswith("_old") else 0.])


def _local_face(points):
    # Independent anatomical envelopes, slightly wider than the intended
    # folds. Neck, torso, back of skull, temples and upper cranium are barred.
    x, y, z = points.T
    nose = (np.abs(x) < .036) & (y > .062) & (y < .160) & (z > .060)
    ear = (np.abs(x) > .073) & (np.abs(x) < .130) & (y > .079) & (y < .173) & (z > -.051) & (z < .023)
    return nose | ear


def _edge_defects(faces):
    edges = np.sort(np.concatenate((faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]])), axis=1)
    unique, counts = np.unique(edges, axis=0, return_counts=True)
    defects = {tuple(int(v) for v in edge): int(count) for edge, count in zip(unique, counts) if count != 2}
    return defects, Counter(int(n) for n in counts)


def _nose_projection(points):
    x, y, z = points.T
    tip = (np.abs(x) < .013) & (y > .079) & (y < .116) & (z > .05)
    cheek = (np.abs(x) > .025) & (np.abs(x) < .040) & (y > .082) & (y < .115) & (z > .05)
    assert np.count_nonzero(tip) >= 8 and np.count_nonzero(cheek) >= 8, "insufficient nose/cheek geometry"
    # A percentile reference rejects a spurious single cheek vertex without
    # confusing the cheek's far/back surface with the visible facial plane.
    projection = float(np.max(z[tip]) - np.percentile(z[cheek], 90))
    assert .012 <= projection <= .050, "nose projection outside 12--50mm head-normalized bounds: %.3fmm" % (projection * 1000)
    return projection


def check_geometry(before, after, body, variant):
    old_mesh, new_mesh = before.mesh(body), after.mesh(body)
    old, new = old_mesh["primitives"][0], new_mesh["primitives"][0]
    old_attrs = {k: before.values(v) for k, v in old["attributes"].items()}
    attrs = {k: after.values(v) for k, v in new["attributes"].items()}
    old_count, count = len(old_attrs["POSITION"]), len(attrs["POSITION"])
    assert count > old_count, "no local refinement"
    for name, values in attrs.items():
        assert len(values) == count and np.isfinite(values).all(), "invalid attribute: " + name
    assert np.allclose(attrs["WEIGHTS_0"].sum(axis=1), 1., atol=2e-5, rtol=0), "skin weights are not normalized"
    assert (attrs["WEIGHTS_0"] >= 0).all(), "negative skin weights"
    body_node = next(n for n in after.doc["nodes"] if n.get("name") == body)
    joint_count = len(after.doc["skins"][body_node["skin"]]["joints"])
    assert attrs["JOINTS_0"].dtype.kind in "iu" and attrs["JOINTS_0"].max() < joint_count, "invalid skin joint"
    faces = after.values(new["indices"]).reshape(-1, 3)
    old_faces = before.values(old["indices"]).reshape(-1, 3)
    assert 0 < len(faces) <= 30000, "body triangle budget exceeded: %d" % len(faces)
    assert faces.dtype.kind in "iu" and faces.min() >= 0 and faces.max() < count, "invalid triangle index"
    assert np.all(faces[:, 0] != faces[:, 1]) and np.all(faces[:, 1] != faces[:, 2]) and np.all(faces[:, 2] != faces[:, 0]), "collapsed index triangle"
    old_defects, old_counts = _edge_defects(old_faces)
    defects, counts = _edge_defects(faces)
    assert defects == old_defects, "topological defects changed: baseline %s, current %s" % (dict(old_counts), dict(counts))
    scale, origin = _frame(before, old, variant)
    base = old_attrs["POSITION"].astype(np.float64)
    q = (base - origin) / scale
    outside = ~_local_face(q)
    np.testing.assert_array_equal(attrs["POSITION"][:old_count][outside], base[outside], err_msg="original position changed outside local face envelope")
    for name in old_attrs:
        if name not in ("POSITION", "NORMAL", "TEXCOORD_1"):
            np.testing.assert_array_equal(attrs[name][:old_count], old_attrs[name], err_msg="original attribute changed: " + name)
    # Vertex colour coverage and the non-facing channels of UV1 must remain
    # untouched even where the new skin is sculpted.
    np.testing.assert_array_equal(attrs["TEXCOORD_1"][:old_count, 1:], old_attrs["TEXCOORD_1"][:, 1:], err_msg="original face coverage/AO changed")
    head = ((attrs["POSITION"] - origin) / scale)[:, 1] > .06
    head_data = {"POSITION": attrs["POSITION"][head], "NORMAL": attrs["NORMAL"][head]}
    old_targets = []
    targets = []
    for i, (a, b) in enumerate(zip(old["targets"], new["targets"])):
        oa = {key: before.values(value) for key, value in a.items()}
        na = {key: after.values(value) for key, value in b.items()}
        old_targets.append(oa)
        targets.append(na)
        for name, values in na.items():
            assert len(values) == count and np.isfinite(values).all(), "invalid morph %d %s" % (i, name)
            head_data["target%d:%s" % (i, name)] = values[head]
        absolute_before = base + oa["POSITION"].astype(np.float64)
        absolute_after = attrs["POSITION"][:old_count].astype(np.float64) + na["POSITION"][:old_count].astype(np.float64)
        fixed = outside & ~_local_face((absolute_before - origin) / scale)
        np.testing.assert_allclose(absolute_after[fixed], absolute_before[fixed], rtol=0, atol=1.5e-7,
                                   err_msg="absolute morph %d moved outside local face envelope" % i)
    names = new_mesh["extras"]["targetNames"]
    negative = attrs["POSITION"].astype(np.float64).copy()
    for name in ("face_nose", "face_bridge"):
        negative -= targets[names.index(name)]["POSITION"]
    neutral_projection = _nose_projection((attrs["POSITION"] - origin) / scale)
    negative_projection = _nose_projection((negative - origin) / scale)
    head_data["faces"] = faces[np.all(head[faces], axis=1)]
    head_data["head_ids"] = np.flatnonzero(head)
    return head_data, {"vertices": count, "triangles": len(faces), "original_vertices_preserved_outside_face": int(outside.sum()),
                       "original_boundary_edges": old_counts.get(1, 0), "original_nonmanifold_edges": sum(n for k, n in old_counts.items() if k > 2),
                       "nose_projection_mm": round(neutral_projection * 1000, 2), "negative_nose_bridge_projection_mm": round(negative_projection * 1000, 2)}


def check(root, baseline_ref):
    root = Path(root).resolve()
    baseline = subprocess.check_output(["git", "rev-parse", "--verify", baseline_ref + "^{commit}"], cwd=root, text=True).strip()
    failures = []
    passed = 0
    for variant in VARIANTS:
        heads = []
        for folder, stem, body in BUNDLES:
            relative = "assets/court_figures/" + folder + "court_" + stem + "_" + variant + ".glb"
            try:
                original = subprocess.check_output(["git", "show", baseline + ":" + relative], cwd=root)
                before, after = Blob(original), Blob((root / relative).read_bytes())
                check_preservation(before, after, body)
                head, result = check_geometry(before, after, body, variant)
                heads.append((stem, head))
                print("COURT_ANATOMY PASS", relative, json.dumps(result, sort_keys=True), flush=True)
                passed += 1
            except (AssertionError, ValueError, KeyError, IndexError, OSError, subprocess.CalledProcessError) as exc:
                failures.append((relative, str(exc)))
                print("COURT_ANATOMY FAIL", relative, str(exc), flush=True)
        if len(heads) == 3:
            try:
                source = heads[0][1]
                for stem, head in heads[1:]:
                    assert source.keys() == head.keys(), "head channels differ for " + stem
                    for key in source:
                        np.testing.assert_array_equal(head[key], source[key], err_msg=variant + " head mismatch in " + stem + ":" + key)
                print("COURT_ANATOMY_HEAD_MATCH PASS", variant, "Body/LegacyBody/WardrobeBody", flush=True)
            except AssertionError as exc:
                failures.append((variant + " head agreement", str(exc)))
                print("COURT_ANATOMY_HEAD_MATCH FAIL", variant, str(exc), flush=True)
    print("COURT_ANATOMY_RESULT", json.dumps({"baseline": baseline, "root": str(root), "files_passed": passed,
                                              "files_expected": 21, "failures": len(failures)}, sort_keys=True), flush=True)
    return 1 if failures else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--baseline-ref", default="304ad0cb68ad21f036a9ec792f15df275e70c544")
    args = parser.parse_args()
    return check(args.root, args.baseline_ref)


if __name__ == "__main__":
    sys.exit(main())
