# Settlement wall LOD continuity

Branch `codex/settlement-wall-lod`; base `03f4db0`.

Wall skirts no longer bake a camera.size > 0.42 color/opacity switch into their
mesh. A shared cached wall shader responds continuously to pixel coverage. This
removes build-zoom-dependent appearance while retaining muted distant wall detail,
normal depth testing, vertex material/condition colors, and existing mesh budgets.

Validation: 80 settlement visual architecture tests PASS. New test builds actual
wall meshes at 0.20, 0.42, 0.43 and 1.0 km; all 24 vertex colors agree exactly.
It checks the real shader assignment, derivative fade, depth behavior and cached
shader reuse. Hidden self-quitting production town capture completed without
shader/parse errors: `artifacts/town-wall-lod.png`. Its overall composition matches
the preceding town fixture; this is a continuity fix, not a town redesign.

No simulation, save, camera limits or menu changes. Existing shutdown resource
warnings remain. Wall shader is intentionally simple and uses no texture samplers;
independent GPU timing has not been measured. Shared hotspot local_terrain.gd:
wall material factory/assignment and removal of camera-dependent wall mesh colors.
