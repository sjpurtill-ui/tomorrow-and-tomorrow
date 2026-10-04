"""Independent preservation and animation-contract audit for MPFB court heads.

The audit reads delivered GLBs and a Git baseline.  It never imports the head
generator or trusts a generator's claimed number of preserved vertices.
"""
import argparse
from collections import Counter
import copy
import json
from pathlib import Path
import subprocess
import sys

import numpy as np
from validate_court_anatomy import Blob, BUNDLES, VARIANTS, _frame


BASELINE = "895481d83e2a74f000582997b0ca469c889b0627"
IDENTITY = tuple("face_" + name for name in
                 ("jaw", "chin", "cheek", "nose", "bridge", "nose_wide",
                  "brow", "lips", "ears", "long", "round", "aged"))
EXPRESSIONS = ("jaw_open", "smile", "frown", "lips_pressed", "sneer", "cheeks_puff",
               "brows_up", "brows_down", "brows_worried", "eyes_wide", "eyes_narrow", "blink",
               "eyes_left", "eyes_right", "eyes_up", "eyes_down",
               "v_aa", "v_ee", "v_oo", "v_mm", "v_fv")
MOODS = ("mood_smile", "mood_tight", "mood_worry", "mood_stern")
GAZE = ("eyes_left", "eyes_right", "eyes_up", "eyes_down")
BODY_TARGETS = set(IDENTITY + tuple(name for name in EXPRESSIONS if name not in GAZE) + MOODS)
GRAFT_FIELDS = {"mpfb_head_revision", "mpfb_cut_y", "mpfb_original_indices",
                "mpfb_original_vertex_count", "mpfb_head_start", "mpfb_source_variant"}


def changed_head_node(name):
    return name in ("Body", "LegacyBody", "WardrobeBody", "Eyes", "Brows", "Mouth") or name.startswith(("hair_", "beard_"))


def check_payload(before, after):
    """Only head mesh records/references and appended data may change."""
    assert after.bin[:len(before.bin)] == before.bin, "original binary prefix changed"
    old, new = before.doc, copy.deepcopy(after.doc)
    # Teeth are the one intentional new material: only the replaced Mouth
    # primitive may use it. Every original material definition remains exact.
    original_materials = old.get("materials", [])
    materials = new.get("materials", [])
    assert materials[:len(original_materials)] == original_materials, "original material changed"
    appended = materials[len(original_materials):]
    assert len(appended) <= 1 and all(material.get("name") == "TEETH" for material in appended), "unexpected appended material"
    if appended:
        teeth_index = len(original_materials)
        mouth = node_for(after, "Mouth")
        users = [index for index, mesh in enumerate(after.doc["meshes"])
                 if any(primitive.get("material") == teeth_index for primitive in mesh["primitives"])]
        assert users == [mouth.get("mesh")], "TEETH must be used only by the Mouth mesh"
    new["materials"] = original_materials
    for key in ("accessors", "bufferViews"):
        assert len(new[key]) > len(old[key]), "no appended " + key
        assert new[key][:len(old[key])] == old[key], "original " + key + " changed"
        new[key] = old[key]
    assert len(new["nodes"]) == len(old["nodes"]), "original scene node count changed"
    allowed_old, allowed_new = set(), set()
    for i, (a, b) in enumerate(zip(old["nodes"], new["nodes"])):
        if changed_head_node(a.get("name", "")):
            if "mesh" in a:
                allowed_old.add(a["mesh"])
            if "mesh" in b:
                allowed_new.add(b["mesh"])
            if "mesh" in a:
                b["mesh"] = a["mesh"]
            else:
                b.pop("mesh", None)
        assert a == b, "node/rig transform or skin changed: %d %s" % (i, a.get("name"))
    assert all(index >= len(old["meshes"]) or index in allowed_old for index in allowed_new), "head now aliases an original garment/prop mesh"
    assert len(new["meshes"]) >= len(old["meshes"]), "original mesh records removed"
    for index in range(len(old["meshes"]), len(new["meshes"])):
        assert index in allowed_new, "unexpected appended non-head mesh"
    new["meshes"] = new["meshes"][:len(old["meshes"])]
    for index in allowed_old:
        new["meshes"][index] = old["meshes"][index]
    assert len(new["buffers"]) == len(old["buffers"]) == 1, "buffer count changed"
    new["buffers"][0]["byteLength"] = old["buffers"][0]["byteLength"]
    assert new == old, "non-head metadata/material/garment/prop/animation changed"


def node_for(glb, name):
    return next(node for node in glb.doc["nodes"] if node.get("name") == name)


def targets(glb, mesh, primitive):
    names = mesh.get("extras", {}).get("targetNames", [])
    values = primitive.get("targets", [])
    assert len(names) == len(values) and len(names) == len(set(names)), "duplicate/mismatched target names"
    return {name: {key: glb.values(value) for key, value in target.items()}
            for name, target in zip(names, values)}


def primitive_arrays(glb, primitive):
    return {name: glb.values(index) for name, index in primitive["attributes"].items()}


def check_mesh(glb, name):
    """Check every referenced base/target array, every index and skin influence."""
    node = node_for(glb, name)
    mesh = glb.doc["meshes"][node["mesh"]]
    assert "skin" in node, name + " lost its skin"
    joints = len(glb.doc["skins"][node["skin"]]["joints"])
    all_motion = Counter()
    vertices = triangles = 0
    for primitive in mesh["primitives"]:
        assert primitive.get("mode", 4) == 4, name + " is not a triangle primitive"
        attrs = primitive_arrays(glb, primitive)
        count = len(attrs["POSITION"])
        assert count > 0, name + " is empty"
        for key, array in attrs.items():
            assert len(array) == count and np.isfinite(array).all(), name + ": invalid " + key
        assert {"POSITION", "NORMAL", "JOINTS_0", "WEIGHTS_0"} <= attrs.keys(), name + " lacks skin attributes"
        assert attrs["JOINTS_0"].dtype.kind in "iu" and np.max(attrs["JOINTS_0"]) < joints, name + " has invalid joints"
        assert np.all(attrs["WEIGHTS_0"] >= 0), name + " has negative weights"
        np.testing.assert_allclose(attrs["WEIGHTS_0"].sum(axis=1), 1., atol=2e-5, rtol=0, err_msg=name + " skin weights")
        indices = glb.values(primitive["indices"])
        assert indices.size % 3 == 0 and indices.dtype.kind in "iu", name + " has invalid triangle indices"
        faces = indices.reshape(-1, 3)
        assert len(faces) > 0 and faces.min() >= 0 and faces.max() < count, name + " has out-of-range indices"
        assert not np.any((faces[:, 0] == faces[:, 1]) | (faces[:, 1] == faces[:, 2]) | (faces[:, 2] == faces[:, 0])), name + " has collapsed index triangles"
        for target_name, channels in targets(glb, mesh, primitive).items():
            assert "POSITION" in channels, name + ": target lacks positions: " + target_name
            for key, array in channels.items():
                assert len(array) == count and np.isfinite(array).all(), name + ": invalid " + target_name + ":" + key
            lengths = np.linalg.norm(channels["POSITION"], axis=1)
            all_motion[target_name] += int(np.count_nonzero(lengths > 1e-6))
        vertices += count
        triangles += len(faces)
    return {"vertices": vertices, "triangles": triangles, "moved_vertices": dict(all_motion)}


def _rows(points):
    contiguous = np.ascontiguousarray(points)
    return contiguous.view(np.dtype((np.void, contiguous.dtype.itemsize * contiguous.shape[1]))).reshape(-1)


def _oriented_faces(faces):
    """Ignore triangle list/cyclic corner order while retaining winding."""
    return Counter(tuple(int(face[(start + j) % 3]) for j in range(3))
                   for face in faces for start in [int(np.argmin(face))])


def retained_body(before, after, body, variant, cut, boundary_old_ids=()):
    """Prove actual lower-body data is retained, independent of vertex order."""
    old_mesh, new_mesh = before.mesh(body), after.mesh(body)
    assert len(old_mesh["primitives"]) == len(new_mesh["primitives"]) == 1, "body must remain one primitive"
    old, new = old_mesh["primitives"][0], new_mesh["primitives"][0]
    oa, na = primitive_arrays(before, old), primitive_arrays(after, new)
    scale, origin = _frame(before, old, variant)
    low = (oa["POSITION"][:, 1] - origin[1]) / scale < cut
    old_ids = np.flatnonzero(low)
    assert len(old_ids) > 3000, "preservation cutoff excludes too much original body"
    new_rows = _rows(na["POSITION"])
    order = np.argsort(new_rows)
    needle = _rows(oa["POSITION"])[old_ids]
    at = np.searchsorted(new_rows[order], needle)
    assert np.all(at < len(order)), "original lower-body vertex missing"
    new_ids = order[at]
    np.testing.assert_array_equal(new_rows[new_ids], needle, err_msg="original lower-body position changed/missing")
    for key in oa:
        assert key in na, "lost lower-body attribute " + key
        fixed = ~np.isin(old_ids, boundary_old_ids) if key == "NORMAL" else np.ones(len(old_ids), dtype=bool)
        np.testing.assert_array_equal(na[key][new_ids[fixed]], oa[key][old_ids[fixed]], err_msg="changed lower-body attribute " + key)
    ot, nt = targets(before, old_mesh, old), targets(after, new_mesh, new)
    assert ot.keys() <= nt.keys(), "original body target missing"
    for target_name, channels in ot.items():
        for key, values in channels.items():
            assert key in nt[target_name], "lost morph channel " + target_name + ":" + key
            fixed = ~np.isin(old_ids, boundary_old_ids) if key == "NORMAL" else np.ones(len(old_ids), dtype=bool)
            np.testing.assert_array_equal(nt[target_name][key][new_ids[fixed]], values[old_ids[fixed]],
                                           err_msg="changed lower-body morph " + target_name + ":" + key)
    for target_name in nt.keys() - ot.keys():
        for key, values in nt[target_name].items():
            fixed = ~np.isin(old_ids, boundary_old_ids) if key == "NORMAL" else np.ones(len(old_ids), dtype=bool)
            np.testing.assert_array_equal(values[new_ids[fixed]], 0., err_msg="new face target affects retained body: " + target_name + ":" + key)
    inverse = np.full(len(na["POSITION"]), -1, dtype=np.int64)
    inverse[new_ids] = old_ids
    old_faces = before.values(old["indices"]).reshape(-1, 3)
    new_faces = after.values(new["indices"]).reshape(-1, 3)
    old_low_faces = old_faces[np.all(low[old_faces], axis=1)]
    new_low_faces = inverse[new_faces]
    new_low_faces = new_low_faces[np.all(new_low_faces >= 0, axis=1)]
    assert _oriented_faces(old_low_faces) == _oriented_faces(new_low_faces), "retained lower-body topology/winding changed"
    referenced = np.unique(new_faces)
    assert np.all(np.isin(new_ids, referenced)), "retained vertices are merely unused stale data"
    return {"retained_vertices": len(old_ids), "retained_triangles": len(old_low_faces)}, scale, origin


def _edge_counts(faces):
    return Counter(tuple(sorted((int(face[a]), int(face[b]))))
                   for face in faces for a, b in ((0, 1), (1, 2), (2, 0)))


def _directed_edge_balance(faces):
    balance = Counter()
    for face in faces:
        for a, b in ((0, 1), (1, 2), (2, 0)):
            left, right = int(face[a]), int(face[b])
            balance[tuple(sorted((left, right)))] += 1 if left < right else -1
    return balance


def _new_cut_edges(old_faces, kept_faces):
    previous = {edge for edge, count in _edge_counts(old_faces).items() if count == 1}
    return {edge for edge, count in _edge_counts(kept_faces).items() if count == 1} - previous


def _retained_cut_faces(points, faces, cut, scale, origin):
    """Keep the body; permit discarding only detached chin remnants."""
    candidates = faces[np.all(points[faces, 1] <= cut, axis=1)]
    used = np.unique(candidates)
    parent = {int(index): int(index) for index in used}

    def find(index):
        index = int(index)
        while parent[index] != index:
            parent[index] = parent[parent[index]]
            index = parent[index]
        return index

    for triangle in candidates:
        root = find(triangle[0])
        for index in triangle[1:]:
            parent[find(index)] = root
    labels = np.asarray([find(triangle[0]) for triangle in candidates])
    components, counts = np.unique(labels, return_counts=True)
    assert len(components), "cut removed the entire original body"
    keep = labels == components[np.argmax(counts)]
    discarded = np.unique(candidates[~keep])
    if len(discarded):
        y = (points[discarded, 1] - origin[1]) / scale
        assert np.all(np.abs(y) <= .020), "discarded component extends beyond the permitted 20mm chin remnants"
    return candidates[keep], discarded


def _welded_neck_edges(points, faces, scale, origin):
    # UV/material splits can duplicate one geometric vertex. Weld positions
    # to micrometre precision before judging the actual visible neck seam.
    rounded = np.round(points.astype(np.float64), 6)
    welded, remap = np.unique(rounded, axis=0, return_inverse=True)
    mapped = remap[faces]
    edges = np.sort(np.concatenate((mapped[:, [0, 1]], mapped[:, [1, 2]], mapped[:, [2, 0]])), axis=1)
    edges = edges[edges[:, 0] != edges[:, 1]]
    unique, counts = np.unique(edges, axis=0, return_counts=True)
    y = (welded[:, 1] - origin[1]) / scale
    neck = np.all((y[unique] >= -.05) & (y[unique] <= 0.), axis=1)
    defects = {}
    for edge, count in zip(unique[neck], counts[neck]):
        if count != 2:
            key = tuple(welded[edge].reshape(-1))
            defects[key] = int(count)
    return defects


def check_graft(before, after, body, variant):
    old_mesh, mesh = before.mesh(body), after.mesh(body)
    old, new = old_mesh["primitives"][0], mesh["primitives"][0]
    extra = mesh.get("extras", {})
    assert GRAFT_FIELDS <= extra.keys(), "graft metadata is incomplete"
    assert extra["mpfb_head_revision"] == 1 and extra["mpfb_source_variant"] == variant, "wrong MPFB graft revision/variant"
    oa, na = primitive_arrays(before, old), primitive_arrays(after, new)
    scale, origin = _frame(before, old, variant)
    cut = float(extra["mpfb_cut_y"])
    assert abs((cut - origin[1]) / scale) <= .002, "graft cut is outside the agreed chin-level neck interval"
    start = extra["mpfb_head_start"]
    assert isinstance(start, int) and start == extra["mpfb_original_vertex_count"], "retained count/head start mismatch"
    mapping_index = extra["mpfb_original_indices"]
    assert isinstance(mapping_index, int) and mapping_index >= len(before.doc["accessors"]), "original-index map was not appended"
    mapping = after.values(mapping_index).reshape(-1)
    assert mapping.dtype.kind in "iu" and len(mapping) == start and len(np.unique(mapping)) == start, "invalid/duplicate retained vertex mapping"
    assert mapping.min() >= 0 and mapping.max() < len(oa["POSITION"]), "retained mapping out of range"
    assert 0 < start < len(na["POSITION"]), "new head is missing"
    for key in oa:
        if key != "NORMAL":
            np.testing.assert_array_equal(na[key][:start], oa[key][mapping], err_msg="retained-prefix attribute changed: " + key)
    old_faces = before.values(old["indices"]).reshape(-1, 3)
    new_faces = after.values(new["indices"]).reshape(-1, 3)
    expected, discarded_chin = _retained_cut_faces(oa["POSITION"], old_faces, cut, scale, origin)
    retained_faces = new_faces[np.all(new_faces < start, axis=1)]
    assert _oriented_faces(mapping[retained_faces]) == _oriented_faces(expected), "retained body triangles do not match the original cut"
    cut_edges = _new_cut_edges(old_faces, expected)
    assert len(cut_edges) >= 8, "original cut boundary was not found"
    boundary_ids = np.unique(np.asarray(list(cut_edges)))
    fixed_prefix = ~np.isin(mapping, boundary_ids)
    np.testing.assert_array_equal(na["NORMAL"][:start][fixed_prefix], oa["NORMAL"][mapping[fixed_prefix]], err_msg="non-boundary retained normals changed")
    old_targets = targets(before, old_mesh, old)
    new_targets = targets(after, mesh, new)
    for name, channels in new_targets.items():
        for key, values in channels.items():
            fixed = fixed_prefix if key == "NORMAL" else np.ones(start, dtype=bool)
            original = old_targets.get(name, {}).get(key)
            expected_values = original[mapping[fixed]] if original is not None else np.zeros_like(values[:start][fixed])
            np.testing.assert_array_equal(values[:start][fixed], expected_values, err_msg="retained-prefix target changed: " + name + ":" + key)
    # Closed but disconnected caps are not an attachment. Every actual old
    # cut edge must receive exactly one triangle reaching the new head, even
    # where the irregular original cut dips below the nominal neck band.
    cross = new_faces[np.any(new_faces < start, axis=1) & np.any(new_faces >= start, axis=1)]
    assert len(cross) >= len(cut_edges), "new head has no complete connecting annulus"
    qy = (na["POSITION"][:, 1] - origin[1]) / scale
    assert np.all((qy[cross] > -.080) & (qy[cross] < .040)), "connecting triangles leave the neck"
    inverse_mapping = {int(old_index): index for index, old_index in enumerate(mapping)}
    cross_edges = _edge_counts(cross)
    all_edges = _edge_counts(new_faces)
    winding = _directed_edge_balance(new_faces)
    for edge in cross_edges:
        assert all_edges[edge] == 2 and winding[edge] == 0, "neck edge has inconsistent winding/incidence: " + str(edge)
    for a, b in cut_edges:
        edge = tuple(sorted((inverse_mapping[a], inverse_mapping[b])))
        assert cross_edges[edge] == 1, "original cut edge not attached exactly once: " + str((a, b))
    head_faces = new_faces[np.all(new_faces >= start, axis=1)]
    head_boundary = {edge for edge, count in _edge_counts(head_faces).items()
                     if count == 1 and max(qy[list(edge)]) < .035}
    assert len(head_boundary) >= 8, "new head neck boundary was not found"
    for edge in head_boundary:
        assert cross_edges[edge] == 1, "new neck boundary not attached exactly once: " + str(edge)
    referenced = np.unique(new_faces)
    assert np.all(np.isin(np.arange(start), referenced)), "unused retained-prefix vertices"
    original_defects = _welded_neck_edges(oa["POSITION"], old_faces, scale, origin)
    new_defects = _welded_neck_edges(na["POSITION"], new_faces, scale, origin)
    assert new_defects == original_defects, "added open/nonmanifold neck seam: original=%d new=%d" % (len(original_defects), len(new_defects))
    target_data = targets(after, mesh, new)
    assert set(target_data) == BODY_TARGETS and len(target_data) == 33, "body must retain twelve identities and twenty-one expression/mood channels"
    old_names = old_mesh["extras"]["targetNames"]
    assert mesh["extras"]["targetNames"][:len(old_names)] == old_names, "original body target order changed"
    head_data = {key: values[start:] for key, values in na.items()}
    head_data["indices"] = new_faces[np.all(new_faces >= start, axis=1)] - start
    identity_moved = {}
    for name, channels in target_data.items():
        for key, values in channels.items():
            head_data[name + ":" + key] = values[start:]
        if name in IDENTITY:
            moved = int(np.count_nonzero(np.linalg.norm(channels["POSITION"][start:], axis=1) > 1e-6))
            assert moved >= 5, "identity is inert on the new head: " + name
            identity_moved[name] = moved
    preserved, _, _ = retained_body(before, after, body, variant, -.040, boundary_ids)
    return head_data, {**preserved, "head_vertices": len(na["POSITION"]) - start,
                       "neck_defects": len(new_defects), "identities_nonzero": len(identity_moved),
                       "discarded_chin_remnant_vertices": len(discarded_chin)}


def check(root, baseline_ref):
    root = Path(root).resolve()
    baseline = subprocess.check_output(["git", "rev-parse", "--verify", baseline_ref + "^{commit}"], cwd=root, text=True).strip()
    failures = []
    passed = matched = 0
    for variant in VARIANTS:
        heads = []
        for folder, stem, body in BUNDLES:
            relative = "assets/court_figures/" + folder + "court_" + stem + "_" + variant + ".glb"
            try:
                original = subprocess.check_output(["git", "show", baseline + ":" + relative], cwd=root)
                before, after = Blob(original), Blob((root / relative).read_bytes())
                check_payload(before, after)
                mesh_result = check_mesh(after, body)
                assert mesh_result["triangles"] <= 30000, "body exceeds the 30,000 triangle budget"
                head, result = check_graft(before, after, body, variant)
                heads.append((stem, head))
                if stem == "figure":
                    motion = Counter(mesh_result["moved_vertices"])
                    for name in ("Eyes", "Brows", "Mouth"):
                        assert "mesh" in node_for(after, name), "missing facial part: " + name
                        part = check_mesh(after, name)
                        if name == "Eyes":
                            for channel in GAZE:
                                assert part["moved_vertices"].get(channel, 0) >= 5, "Eyes lacks working gaze: " + channel
                        motion.update(part["moved_vertices"])
                    for name in IDENTITY + EXPRESSIONS + MOODS:
                        assert motion[name] >= 5, "missing/inert court face channel: " + name
                    for node in after.doc["nodes"]:
                        name = node.get("name", "")
                        if name.startswith(("hair_", "beard_")) and "mesh" in node:
                            check_mesh(after, name)
                    result["working_face_channels"] = len(IDENTITY + EXPRESSIONS + MOODS)
                result.update(vertices=mesh_result["vertices"], triangles=mesh_result["triangles"])
                print("MPFB_HEAD PASS", relative, json.dumps(result, sort_keys=True), flush=True)
                passed += 1
            except (AssertionError, ValueError, KeyError, IndexError, StopIteration, OSError, subprocess.CalledProcessError) as exc:
                failures.append((relative, str(exc)))
                print("MPFB_HEAD FAIL", relative, str(exc), flush=True)
        if len(heads) == 3:
            try:
                original = heads[0][1]
                for stem, head in heads[1:]:
                    assert original.keys() == head.keys(), "cross-bundle head channels differ"
                    for key in original:
                        np.testing.assert_array_equal(head[key], original[key], err_msg=variant + ":" + stem + ":" + key)
                matched += 1
                print("MPFB_HEAD_MATCH PASS", variant, flush=True)
            except AssertionError as exc:
                failures.append((variant + " cross-bundle head", str(exc)))
                print("MPFB_HEAD_MATCH FAIL", variant, str(exc), flush=True)
    report = {"baseline": baseline, "root": str(root), "files_passed": passed,
              "files_expected": 21, "matched_variant_heads": matched, "failures": failures}
    print("MPFB_HEAD_RESULT", json.dumps(report, sort_keys=True), flush=True)
    return 1 if failures else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--baseline-ref", default=BASELINE)
    args = parser.parse_args()
    return check(args.root, args.baseline_ref)


if __name__ == "__main__":
    sys.exit(main())
