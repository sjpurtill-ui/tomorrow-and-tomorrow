"""Reverse only the two backwards-authored base walk cycles, preserving poses.

python tools/blender/correct_court_walk_cycles.py --source-ref d7d4850c

Reads an explicit pre-correction Git revision. Refuses assets differing from
both that source and its corrected result, so rerunning cannot reverse twice
or discard later head/clothing work. Fresh exports use cf_anim's corrected clock.
"""
import argparse
import json
from pathlib import Path
import struct
import subprocess

import numpy as np

VARIANTS = ("male_adult", "female_adult", "male_old", "female_old",
            "male_young", "female_young", "child")
WALKS = {"walk_in", "walk_out"}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def correct(raw):
    size = struct.unpack_from("<I", raw, 12)[0]
    doc = json.loads(raw[20:20 + size])
    start = 28 + size
    result = bytearray(raw)

    def array(index, buffer=raw):
        a = doc["accessors"][index]
        v = doc["bufferViews"][a["bufferView"]]
        assert a["componentType"] == 5126 and "sparse" not in a
        width = WIDTHS[a["type"]]
        return np.ndarray((a["count"], width), dtype="<f4", buffer=buffer,
                          offset=start + v.get("byteOffset", 0) + a.get("byteOffset", 0),
                          strides=(v.get("byteStride", width * 4), 4))

    protected = {s[key] for a in doc["animations"] if a["name"] not in WALKS
                 for s in a["samplers"] for key in ("input", "output")}
    # Geometry and every original accessor outside the selected outputs must
    # remain byte-identical, including inputs shared with other animations.
    edited = set()
    found = set()
    for animation in doc["animations"]:
        if animation["name"] not in WALKS:
            continue
        found.add(animation["name"])
        duration = max(float(array(s["input"])[-1, 0]) for s in animation["samplers"])
        for sampler in animation["samplers"]:
            times = array(sampler["input"])[:, 0]
            values = array(sampler["output"])
            groups = values.reshape(len(times), -1, values.shape[1])
            if sampler.get("interpolation", "LINEAR") == "STEP":
                assert np.all(groups == groups[0]), "Only constant STEP tracks are supported"
                continue
            assert sampler.get("interpolation", "LINEAR") == "LINEAR"
            # These baked clips have uniform 30 Hz keys. Fail if a future
            # exporter needs reversed timestamps too; never corrupt its timing.
            assert np.allclose(times, duration - times[::-1], atol=2e-7)
            assert np.allclose(groups[0], groups[-1], atol=1e-6), "Walk must be a closed loop"
            output = sampler["output"]
            assert output not in protected, "Walk output shared with another clip"
            if output not in edited:
                array(output, result)[:] = groups[::-1].reshape(values.shape)
                edited.add(output)
    assert found == WALKS
    # Prove that mesh data, morphs, rig and other clips retain every byte.
    for index in range(len(doc["accessors"])):
        if index in edited:
            continue
        a = doc["accessors"][index]
        if "bufferView" not in a:
            continue
        v = doc["bufferViews"][a["bufferView"]]
        offset = start + v.get("byteOffset", 0)
        assert raw[offset:offset + v["byteLength"]] == result[offset:offset + v["byteLength"]]
    return bytes(result), len(edited)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-ref", required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    pending = []
    for variant in VARIANTS:
        relative = f"assets/court_figures/court_figure_{variant}.glb"
        raw = subprocess.check_output(["git", "show", f"{args.source_ref}:{relative}"], cwd=root)
        fixed, count = correct(raw)
        path = root / relative
        assert path.read_bytes() in (raw, fixed), f"Refusing unrelated asset changes: {relative}"
        pending.append((path, fixed, count))
    for path, fixed, count in pending:
        temporary = path.with_suffix(".walk-tmp")
        temporary.write_bytes(fixed)
        temporary.replace(path)
        print(f"{path.name}: {count} walk channels corrected; all other accessors unchanged", flush=True)


if __name__ == "__main__":
    main()
