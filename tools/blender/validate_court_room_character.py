"""Raw contact, capability and layout invariants for the room character pass.

Run after validate_court_chapters.py. The baseline comparison reads Git objects;
it never checks out files or imports assets. No Godot or Blender is required.
"""
import argparse
import hashlib
import json
import struct
import subprocess

from validate_court_chapters import ROOT, ASSETS, glb_read, glb_decode, accessor_bytes


def git_file(ref, path):
    return subprocess.check_output(["git", "show", f"{ref}:{path}"], cwd=ROOT)


def mesh_geometry(doc, binary):
    result = {}
    for node in doc["nodes"]:
        if "mesh" not in node:
            continue
        surfaces = []
        for primitive in doc["meshes"][node["mesh"]]["primitives"]:
            digest = hashlib.sha256()
            points = accessor_bytes(doc, binary, primitive["attributes"]["POSITION"])
            points = [points[n:n + 12] for n in range(0, len(points), 12)]
            raw_indices = accessor_bytes(doc, binary, primitive["indices"])
            index_type = doc["accessors"][primitive["indices"]]["componentType"]
            indices = [i[0] for i in struct.iter_unpack("<H" if index_type == 5123 else "<I", raw_indices)]
            # Blender can reorder identical triangles on export. Compare exact
            # vertex bytes and winding, independent of harmless index ordering.
            triangles = []
            for n in range(0, len(indices), 3):
                tri = tuple(points[j] for j in indices[n:n + 3])
                triangles.append(min(tri, tri[1:] + tri[:1], tri[2:] + tri[:2]))
            for tri in sorted(triangles):
                digest.update(b"".join(tri))
            surfaces.append((doc["materials"][primitive["material"]]["name"], digest.hexdigest()))
        result[node["name"]] = sorted(surfaces)
    return result


def changed_content(name):
    return name.endswith("_Records") or name.startswith(("RecordSheet_", "BoundRecord_")) or name == "InstitutionAssembly"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline-ref", default="05c9ecce98486738b60236844dc51dc4dcdc1aba")
    args = parser.parse_args()
    baseline = json.loads(git_file(args.baseline_ref, "assets/court_sets/court_chapters.json"))["sets"]
    current = json.loads((ASSETS / "court_chapters.json").read_text())["sets"]
    checked_meshes, checked_groups = 0, 0
    for key, info in current.items():
        old = baseline[key]
        assert info["marks"] == old["marks"], (key, "changed movement/seat marks")
        assert info["apertures"] == old["apertures"], (key, "changed window opening")
        if info["indoor"]:
            light = info["light"]
            assert light["sun_dir"][1] < 0 and light["sun_dir"][2] > 0, (key, "sun must enter rear windows")
            assert -.30 <= light["sun_dir"][0] <= .30, (key, "unbounded lateral shadow wedge")
            assert light["aperture_z"] == -3.78 and .025 <= light["daylight_strength"] <= .07, key
            assert len(info["fx"]["fill"]) <= 2 and light["sun_energy"] <= .65, key
            assert info["material_overrides"]["WOOD"]["pattern"] == 16, (key, "joinery uses bark pattern")
            assert "BARK" not in info["material_overrides"], (key, "raw timber finish changed")
        dressing = info.get("dressing", {})
        assert len(dressing) <= 6, (key, "unbounded work detail count")
        for name, detail in dressing.items():
            support = detail["support"]
            assert support in old["bounds"], (key, name, "requires original support")
            bounds, surface = info["bounds"][name], info["bounds"][support]
            assert all(bounds[0][a] >= surface[0][a] - .002 and bounds[1][a] <= surface[1][a] + .002
                       for a in (0, 2)), (key, name, "outside support footprint")
            if detail["kind"] == "desktop":
                assert abs(bounds[0][1] - surface[1][1]) <= .002, (key, name, "floating/embedded desktop group")
                assert bounds[1][1] <= surface[1][1] + .16, (key, name, "obscures desk sightline")
            else:
                assert detail["kind"] == "shelf" and surface[0][1] <= bounds[0][1] < bounds[1][1] <= surface[1][1], (key, name)
            cap = detail["capability"]
            assert cap in ("writing", "paper", "bound_records"), (key, name, cap)
            group = "gates" if cap == "writing" else "technology_gates"
            assert name in info[group].get(cap, []), (key, name, "ungated work object")
            checked_groups += 1
        _, doc, binary = glb_read(ASSETS / info["glb"])
        _, old_doc, old_binary = glb_decode(git_file(args.baseline_ref, "assets/court_sets/" + old["glb"]))
        meshes, originals = mesh_geometry(doc, binary), mesh_geometry(old_doc, old_binary)
        assert set(originals) <= set(meshes), (key, "lost original named mesh")
        for name, geometry in originals.items():
            if changed_content(name):
                continue
            assert info["bounds"][name] == old["bounds"][name], (key, name, "layout bounds changed")
            assert meshes[name] == geometry, (key, name, "original geometry/material assignment changed")
            checked_meshes += 1
        assert set(meshes) - set(originals) <= set(dressing), (key, "unregistered new geometry")
        print(f"PASS {key}: original marks/structure, inward light, {len(dressing)} supported gated work groups")
    print(f"PASS 16 rooms; {checked_meshes} original meshes exact triangle geometry/materials; {checked_groups} supported work groups")


if __name__ == "__main__":
    main()
