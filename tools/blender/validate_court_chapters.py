"""Raw asset contracts for additive court chapters; no Blender/Godot import needed.

Run from any directory: python tools/blender/validate_court_chapters.py
The runtime navigation suite separately rasterizes actual triangles and tests routes.
"""
import hashlib
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets" / "court_sets"
CAPABILITIES = {
    "glazing", "paper", "bound_records", "printing", "typewriter", "telephone",
    "electricity", "fluorescent", "radiator", "air_conditioning", "computer", "flat_screen",
}
EQUIPMENT = {
    "Glazing": "glazing", "BoundRecord": "bound_records", "ElectricLamp": "electricity",
    "Telephone": "telephone", "Typewriter": "typewriter", "Computer": "computer",
    "FlatDisplay": "flat_screen", "BriefingDisplay": "flat_screen", "Radiator": "radiator",
    "AirConditioning": "air_conditioning", "Fluorescent": "fluorescent",
    "ConferenceLight": "electricity", "LinearPendant": "electricity",
}


def glb_read(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<III", data)
    assert magic == 0x46546C67 and version == 2 and length == len(data), path
    offset = 12
    doc, binary = None, None
    while offset < len(data):
        length, kind = struct.unpack_from("<II", data, offset)
        chunk = data[offset + 8:offset + 8 + length]
        if kind == 0x4E4F534A:
            doc = json.loads(chunk)
        elif kind == 0x004E4942:
            binary = chunk
        offset += 8 + length
    assert doc is not None and binary is not None, path
    return data, doc, binary


def accessor_bytes(doc, binary, index):
    accessor = doc["accessors"][index]
    view = doc["bufferViews"][accessor["bufferView"]]
    width = {5123: 2, 5125: 4, 5126: 4}[accessor["componentType"]]
    size = width * {"SCALAR": 1, "VEC3": 3}[accessor["type"]]
    stride = view.get("byteStride", size)
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    return b"".join(binary[start + i * stride:start + i * stride + size] for i in range(accessor["count"]))


def horizontal_clearance(point, bounds):
    low, high = bounds
    return math.hypot(max(low[0] - point[0], 0, point[0] - high[0]),
                      max(low[2] - point[2], 0, point[2] - high[2]))


def floor_obstacles(info):
    # Everything intersecting walking-body height. Curved overhead arches have
    # separate piers so this conservative AABB test cannot fill the entire arch.
    return {name: bounds for name, bounds in info["bounds"].items()
            if bounds[0][1] < 1.55 and bounds[1][1] > .12
            and not name.startswith(("Floor", "Ground", "Trees"))}


def main():
    manifest = json.loads((ASSETS / "court_chapters.json").read_text())
    sets = manifest["sets"]
    assert set(sets) == {f"chapter_{i:02}" for i in range(16)}
    shapes, total_triangles, total_bytes, seats = set(), 0, 0, 0
    for i in range(16):
        key = f"chapter_{i:02}"
        info = sets[key]
        assert info["chapter"] == i and info["elapsed_year"] == i * 200, key
        assert info["floor"] in ("earth", "wood", "stone"), key
        assert info["rustic_trophies"] == (i < 9), key
        assert info["indoor"] == (i != 0), key
        assert info["has_hearth"] == (i in (0, 1, 7, 8)), key
        assert info["has_hearth"] == ("fire" in info["marks"]) == ("fire" in info["fx"]), key
        assert "focus" in info["marks"] and "execution" in info["marks"], key
        apertures = info["apertures"]
        if 0 < i <= 3:
            assert max(width * (head - sill) for x, width, sill, head in apertures) <= 1.05, (key, "early oversized window")
        if i:
            assert 1 <= len(info["fx"]["fill"]) <= 2, (key, "bounded daylight fills")
            assert all(len(fill) == 5 and 0 < fill[3] <= .4 for fill in info["fx"]["fill"]), key
        if info["indoor"]:
            assert "smoke_top" not in info["fx"] and not info["fx"].get("smoke", False), key
            assert not any(n.startswith(("animal", "dog", "chicken")) for n in info["marks"]), key
        data, doc, binary = glb_read(ASSETS / info["glb"])
        assert hashlib.sha256(data).hexdigest() == info["sha256"], key
        roots = doc["scenes"][doc.get("scene", 0)]["nodes"]
        names = set()
        geometry = hashlib.sha256()
        triangles, keyboards_checked = 0, 0
        for node_index in roots:
            node = doc["nodes"][node_index]
            assert "mesh" in node and not node.get("children"), (key, node)
            assert not any(t in node for t in ("matrix", "translation", "rotation", "scale")), (key, node)
            name = node["name"]
            assert name not in names and "Merged" not in name, (key, name)
            names.add(name)
            for primitive in doc["meshes"][node["mesh"]]["primitives"]:
                positions = primitive["attributes"]["POSITION"]
                geometry.update(accessor_bytes(doc, binary, positions))
                geometry.update(accessor_bytes(doc, binary, primitive["indices"]))
                triangles += doc["accessors"][primitive["indices"]]["count"] // 3
                if i == 13 and name.startswith("Typewriter") and doc["materials"][primitive["material"]]["name"] == "PAPER":
                    keyboards_checked += 1
                    keys = doc["accessors"][positions]
                    key_z = (keys["min"][2] + keys["max"][2]) / 2
                    if name in ("Typewriter_0", "Typewriter_1"):
                        assert key_z < -1.2, (name, "keys face away from seated typist")
                    else:
                        assert key_z > -2.85, (name, "secretary keys face away from front approach")
        assert names == set(info["objects"]) == set(info["bounds"]), key
        if i in (1, 7, 8):
            assert "HearthstoneInset" in names, (key, "fire on combustible floor")
            hearth = info["bounds"]["HearthstoneInset"]
            assert hearth[0][0] <= -1.1 and hearth[1][0] >= 1.1 and hearth[1][1] < .025, key
        if 0 < i <= 9:
            shutters = {name for name in names if name.startswith("Shutter_")}
            assert shutters and shutters <= set(info["technology_gates"]["no_glazing"]), key
        if i == 14:
            assert "Computer_0" not in names and "Computer_1" not in names and "Computer_2" in names, "conference CRTs obstruct rear officials"
        if i == 15:
            for display in ("FlatDisplay_0", "FlatDisplay_1"):
                assert info["bounds"][display][1][1] <= 1.06, (display, "meeting display face sightline")
        if i == 13:
            assert keyboards_checked == 3, "all three keyboard faces must be checked"
        assert triangles == info["triangles"] and triangles < 12000, (key, triangles)
        if i == 3:
            for column in range(4):
                assert info["bounds"][f"AudienceCapital_{column}"][1][1] > info["bounds"][f"AudiencePier_{column}"][1][1] + .01, "coplanar capital top"
        if i == 12:
            assert info["bounds"]["ConsultationPartition"][0][0] > info["bounds"]["SecretaryStation"][1][0] + .04, "partition intersects secretary desk"
        shape = geometry.hexdigest()
        assert shape not in shapes, (key, "geometry duplicates earlier chapter")
        shapes.add(shape)
        for group in ("gates", "technology_gates", "institution_gates"):
            for gate, objects in info[group].items():
                assert set(objects) <= names, (key, group, gate)
                if group == "technology_gates":
                    assert gate.removeprefix("no_") in CAPABILITIES, (key, gate)
        for name in names:
            if name.endswith("_Records"):
                assert name in info["gates"].get("writing", []) or name in info["technology_gates"].get("bound_records", []), (key, name, "ungated records")
            for prefix, capability in EQUIPMENT.items():
                if name.startswith(prefix):
                    assert name in info["technology_gates"].get(capability, []), (key, name)
            if name.startswith(("RecordSheet", "BoundRecord", "ElectricLamp", "Telephone", "Typewriter", "Computer", "FlatDisplay")):
                assert abs(info["bounds"][name][0][1] - .76) < .002, (key, name, "desk contact")
        obstacles = floor_obstacles(info)
        for name, mark in info["marks"].items():
            if not name.startswith("officials_") or not i:
                continue
            seats += 1
            assert mark["sit"] and mark["external_seat"] and mark["seat"] == .47, (key, name)
            assert mark["seat_mesh"] in names and len(mark["face"]) == 3, (key, name)
            for field in ("seat_exit", "seat_approach"):
                if field in mark:
                    assert len(mark[field]) == 3 and mark[field][1] == 0, (key, name, field)
            nearest, distance = min(((obj, horizontal_clearance(mark["seat_exit"], bounds))
                                     for obj, bounds in obstacles.items()), key=lambda p: p[1])
            assert distance >= .65 - .002, (key, name, "exit", nearest, distance)
        for name, mark in info["marks"].items():
            if not (name in ("petitioner", "execution", "door") or name.startswith(("crowd_", "envoy_"))):
                continue
            point = mark["pos"]
            nearest, distance = min(((obj, horizontal_clearance(point, bounds))
                                     for obj, bounds in obstacles.items()), key=lambda p: p[1])
            assert distance >= .42, (key, name, nearest, distance)
        total_triangles += triangles
        total_bytes += len(data)
        print(f"PASS {key}: {triangles} triangles, {len(names)} named meshes, technology and floor contracts")
    assert seats == 90
    print(f"PASS 16 unique rooms; {seats} authored seats; {total_triangles} triangles; {total_bytes} bytes")


if __name__ == "__main__":
    main()
