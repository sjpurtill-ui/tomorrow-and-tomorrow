# Late roof lighting correction

Base 0350465ee8cd6a4f4588212924ac6e0c3bff1739; branch codex/roof-lighting-normals.

Diagnostic mesh inspection found every normal on late pitched roof columns 0, 1 and 2 pointing downward (12/12 vertices per roof); early roofs and late flat roofs pointed upward. Reverse only the triangle winding of those late pitched faces. Geometry positions, vertex colors, texture coordinates, counts, materials, saves and simulation are unchanged.

77 settlement/material tests pass. New regression checks upward normals for four roof columns in both eras at three orientations. Inspected artifacts/town-roofs-lit.png against town-roads-after.png: late roof faces now receive daylight rather than shading their backs. Existing capture shutdown resource warnings persist.

Shared scope is only the late roof_faces iteration in _append_roof_footprint, plus the existing settlement architecture test. The temporary diagnostic script was replaced by the permanent regression. No player launch.
