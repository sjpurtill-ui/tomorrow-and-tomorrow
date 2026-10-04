"""Inspect real skinned legacy cloth, distinguishing visible cover loss from folds.

Use with tools/court_legacy_motion_audit.tscn. This is a diagnostic, not an
automatic visual acceptance gate: reported cover samples and strained edges
must be inspected in the game's renderer. No geometry or masks are modified.
"""
import argparse
import json
from collections import defaultdict
from pathlib import Path
import numpy as np
from validate_court_walking_cloth import intersections


def edges(faces):
    return np.unique(np.sort(np.concatenate((faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]])), axis=1), axis=0)


def nearest_hits(origin, targets, triangles, projected_bounds=True):
    result = np.full(len(targets), np.inf)
    all_a = triangles[:, 0]
    all_e1, all_e2 = triangles[:, 1] - all_a, triangles[:, 2] - all_a
    forward=triangles.mean(axis=(0,1))-origin
    can_project=projected_bounds and np.linalg.norm(forward)>1e-9
    if can_project:
        forward/=np.linalg.norm(forward)
        right=np.cross(forward,[0.,1.,0.] if abs(forward[1])<.95 else [1.,0.,0.]);right/=np.linalg.norm(right)
        up=np.cross(right,forward);relative=triangles-origin
        depth=relative@forward;uncullable=depth.min(axis=1)<=1e-9
        screen=np.stack((relative@right,relative@up),axis=-1)/np.where(abs(depth)>1e-9,depth,1e-9)[:,:,None]
        low,high=screen.min(axis=1),screen.max(axis=1)
    for start in range(0, len(targets), 16):
        direction = targets[start:start+16] - origin
        candidates=np.ones(len(triangles),dtype=bool)
        if can_project and np.all(direction@forward>1e-9):
            screen=np.column_stack((direction@right,direction@up))/(direction@forward)[:,None]
            # Conservative perspective bounds. Triangles crossing the camera
            # plane always remain candidates; no near-plane approximation.
            candidates=uncullable | (np.all(high>=screen.min(axis=0)-1e-8,axis=1)&np.all(low<=screen.max(axis=0)+1e-8,axis=1))
        if not np.any(candidates):continue
        a,e1,e2=all_a[candidates],all_e1[candidates],all_e2[candidates]
        length = np.linalg.norm(direction, axis=1)
        direction /= length[:, None]
        h = np.cross(direction[:, None], e2)
        determinant = np.sum(e1 * h, axis=2)
        inv = np.divide(1., determinant, out=np.zeros_like(determinant), where=np.abs(determinant) > 1e-10)
        relative = origin - a
        u = np.sum(relative * h, axis=2) * inv
        q = np.cross(relative, e1)
        v = np.sum(direction[:, None] * q, axis=2) * inv
        t = np.sum(e2 * q, axis=1)[None] * inv
        valid = (np.abs(determinant) > 1e-10) & (u >= -1e-5) & (v >= -1e-5) & (u+v <= 1.00001) & (t >= 0)
        result[start:start+16] = np.min(np.where(valid, t, np.inf), axis=1)
    return result


def records(path):
    with open(path, encoding="utf-8-sig") as stream:
        for line in stream:yield json.loads(line)


def inspect(path, coverage=False, hands=False, bare_hands=False):
    meshes = {}; reports = []; groups = defaultdict(lambda: {"poses": 0, "large_strained_edges": 0, "visible_uncovered_samples": 0, "hand_crossing_poses": 0, "bare_body_hand_crossing_poses":0})
    for record in records(path):
        key = (record["variant"], record["outfit"])
        if record["kind"] == "mesh":
            assert record["body_position_mismatches"] == 0, "Replacement changed original body geometry"
            record["body_triangles"] = np.array(record["body_triangles"]).reshape(-1, 3)
            if hands or bare_hands:
                record["hand_faces"] = np.array(record["hand_triangles"]).reshape(-1,3)
                record["hand_edges"] = edges(record["hand_faces"])
            if bare_hands:
                record["leg_faces"] = np.array(record["leg_triangles"]).reshape(-1,3)
                record["leg_edges"] = edges(record["leg_faces"])
            for piece in record["pieces"]:
                piece["faces"] = np.array(piece["triangles"]).reshape(-1, 3)
                piece["edges"] = edges(piece["faces"])
                rest = np.array(piece["rest"])
                piece["lengths"] = np.linalg.norm(rest[piece["edges"][:, 0]] - rest[piece["edges"][:, 1]], axis=1)
                if hands:
                    piece["lower_faces"] = np.array(piece["lower_triangles"],dtype=int).reshape(-1,3)
                    piece["lower_edges"] = edges(piece["lower_faces"])
            meshes[key] = record; continue
        meta = meshes[key]; group = " ".join((*key, record["clip"]))
        groups[group]["poses"] += 1
        detail = {"pose": group, "time": record["time"], "pieces": []}
        if bare_hands:
            body = np.array(record["body"])
            body_hits = intersections(body[meta["hand_edges"]],body[meta["leg_faces"]])
            body_hits += intersections(body[meta["leg_edges"]],body[meta["hand_faces"]])
            if body_hits:
                detail["bare_body_hand_crossings"]={"count":len(body_hits),"first":body_hits[0]}
                groups[group]["bare_body_hand_crossing_poses"] += 1
        shell = []
        if hands:
            body = np.array(record["body"]); hits = []
        for definition, points in zip(meta["pieces"], record["pieces"]):
            points = np.array(points); shell.append(points[definition["faces"]])
            if hands and len(definition["lower_faces"]):
                hits += intersections(body[meta["hand_edges"]],points[definition["lower_faces"]])
                hits += intersections(points[definition["lower_edges"]],body[meta["hand_faces"]])
            lengths = np.linalg.norm(points[definition["edges"][:, 0]] - points[definition["edges"][:, 1]], axis=1)
            ratio = lengths / np.maximum(definition["lengths"], 1e-9)
            delta = lengths - definition["lengths"]
            bad = (definition["lengths"] > .004) & (ratio > 2.6) & (delta > .04)
            if np.any(bad):
                worst = int(np.argmax(np.where(bad, delta, -np.inf)))
                detail["pieces"].append({"name": definition["name"], "count": int(bad.sum()), "max_absolute_extension": float(delta[bad].max()), "max_ratio": float(ratio[bad].max()), "worst_edge": definition["edges"][worst].tolist(), "worst_rest_length": float(definition["lengths"][worst]), "worst_posed_points": points[definition["edges"][worst]].tolist()})
                groups[group]["large_strained_edges"] += int(bad.sum())
        if coverage and record["clip"].startswith(("kneel", "sit_cross")) and (record["time"] >= .6 or record["clip"].endswith("_release")):
            body = np.array(record["body"]); body_tri = body[meta["body_triangles"]]; cloth_tri = np.concatenate(shell)
            ids = sorted(set(meta["newly_hidden"] + meta["hidden"][::max(1, len(meta["hidden"]) // 128)]))
            targets = body[ids]; uncovered = []
            for yaw in (-20, 70):
                angle = np.deg2rad(-yaw); k = meta["height"] / 1.72
                camera = np.array([4.8*k*np.sin(angle), meta["height"]*.8, 4.8*k*np.cos(angle)])
                depth = np.linalg.norm(targets - camera, axis=1)
                body_hit = nearest_hits(camera, targets, body_tri)
                cloth_hit = nearest_hits(camera, targets, cloth_tri)
                visible = (body_hit >= depth - .002*k) & np.isfinite(body_hit)
                holes = visible & (cloth_hit > depth + .002*k)
                uncovered.extend({"vertex": int(ids[i]), "yaw": yaw, "position": targets[i].tolist()} for i in np.flatnonzero(holes))
            detail["visible_uncovered_samples"] = uncovered
            groups[group]["visible_uncovered_samples"] += len(uncovered)
        if hands and hits:
            detail["hand_crossings"] = {"count":len(hits),"first":hits[0]}
            groups[group]["hand_crossing_poses"] += 1
        if detail["pieces"] or detail.get("visible_uncovered_samples") or detail.get("hand_crossings") or detail.get("bare_body_hand_crossings"): reports.append(detail)
    result = {"groups": dict(groups), "flagged_poses": reports, "coverage_enabled": coverage, "hands_enabled":hands, "bare_hands_enabled":bare_hands}
    output = Path(path).with_suffix(".diagnosis.json"); output.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({"poses": sum(v["poses"] for v in groups.values()), "groups": dict(groups), "report": str(output)}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(); parser.add_argument("poses"); parser.add_argument("--coverage", action="store_true"); parser.add_argument("--hands",action="store_true")
    parser.add_argument("--bare-hands",action="store_true")
    args = parser.parse_args(); inspect(args.poses, args.coverage, args.hands,args.bare_hands)
