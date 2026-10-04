# Court room character pass

Worker branch: `codex/court-room-character`, based on `05c9ecce98486738b60236844dc51dc4dcdc1aba`.

Status: asset checkpoint ready for combined renderer review; **HELD pending that visual gate**. This worker has not integrated main or launched the player game.

The sixteen existing room chapters now use deliberately inward rear-window sunlight, restrained warm keys and cool fills, and authored aperture/daylight metadata. Cut joinery uses finished directional wood rather than bark furrows; existing bark/log materials remain distinct. Existing tablet and book shelves gain varied records, and existing working surfaces gain small capability-gated writing groups. Institutional panels have plain wooden frames without invented symbols or factual text. Furniture, chairs, marks, room layout, and garments are unchanged.

The additive `dressing` metadata identifies each new desktop/shelf group, its existing support, and its required capability. Writing uses the existing era gate; paper and bound records use the existing technology gates. New geometry is static, separately named, and stays on existing surfaces. `light.aperture_z` is -3.78; indoor `sun_dir.z` is positive; `daylight_strength` is .055 in older rooms, .045 in chapters 10–13 and .03 in chapters 14–15. There are at most two diffuse daylight fills per room. Root owns the matching runtime daylight and material response.

Validation at this checkpoint:

- Headless Blender 5.2 rebuilt all sixteen rooms successfully.
- Existing raw asset validator passed 16/16: 140,712 triangles total, maximum 11,856 in chapter 13, 13,599,160 bytes, and 90 authored seats. Every room remains below 12,000 triangles; gate names, equipment contacts, seat exits, and foreground floor clearance pass.
- Additional support-contact and baseline mark/geometry invariants are being added separately. Combined actual Godot imagery and runtime gating remain pending; no visual acceptance is claimed from the raw build.

No simulation or save format changes. Existing capability selection remains authoritative. Shared integration files are the additive chapter manifest and generator; runtime/shader work is owned by the integrator. Generated imports, caches, and unrelated files are excluded.
