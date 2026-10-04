# MPFB court authoring setup

Verified on October 4, 2026 with Blender 5.2.0 LTS and MPFB 2.0.17,
build 20260820. MPFB and the MakeHuman system assets were already installed and
enabled on the Windows authoring machine. This task added the five packs below.
The court now uses derived MPFB heads through the adapter documented in
`docs/COURT_MPFB_HANDOFF.md`. Blender/MPFB is an authoring dependency; the game
loads committed GLBs and does not need MPFB installed.

## Assets and provenance

All five ZIPs came from the official MakeHuman download links. Their embedded
pack metadata declares CC0; ZIP integrity, safe extraction paths and existing
file conflicts were checked before installing through `bpy.ops.mpfb.load_pack`.

| Pack | Purpose | SHA-256 of downloaded ZIP |
| --- | --- | --- |
| [nose01](https://static.makehumancommunity.org/assets/assetpacks/nose01.html) | Nose and nostril detail | `21ab5bbd05ec3f1ccad44ff2d7a679cf8f2d8e8b368f5b7367ba00c7701db906` |
| [ears01](https://static.makehumancommunity.org/assets/assetpacks/ears01.html) | Ear anatomy detail | `d32691d10015c7cd0f382f0101dca375153ecfaabd2a875d2b26cc38e17a30dd` |
| [cheek01](https://static.makehumancommunity.org/assets/assetpacks/cheek01.html) | Cheek detail | `ee96e19850878bbacaa8ac2b6a8ea871b667d36b21ca079e74062385b8fae1e9` |
| [faceunits01](https://static.makehumancommunity.org/assets/assetpacks/faceunits01.html) | ARKit-style expressions | `d113107bd7eb59f3af4df6fc0ec29bfcc593f496d0b336aec14f086a80ce7146` |
| [visemes02](https://static.makehumancommunity.org/assets/assetpacks/visemes02.html) | Meta/Oculus speech shapes | `a69ab6fb95ddd5f56f70acc7e859f5f9c6ae613c527d577ea1571eff2183d29e` |

The [system assets](https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html)
provide eyes, skins, teeth, tongue, brows, mesh hair and starter clothing. The
asset license is separate from MPFB's GPL software license; see the
[MPFB license](https://github.com/makehumancommunity/mpfb2/blob/master/LICENSE.md)
and [facial-target repository](https://github.com/makehumancommunity/extra-targets).

## Access and use

In Blender's 3D Viewport, press **N** and open the **MPFB** sidebar tab.
Create a human under **New human → From scratch**, adjust anatomy under **Model**,
add a GameEngine rig, then add skin, eyes and other parts under **Apply assets**.
The nose/ear/cheek packs add modeling targets, rather than standalone heads.

For another machine, install MPFB from the
[official extension platform](https://extensions.blender.org/add-ons/mpfb/),
then load the system-assets ZIP and the five packs through
**Apply assets → Library settings → Load pack from zip file**. Restart Blender
if needed. These are per-machine dependencies, not installed by cloning Git.

**Operations → Export copy** can bake identity targets, add facial units and
Meta visemes, interpolate them onto child meshes, and remove helper geometry.
Use GLB for the Godot prototype. The installed code actually loads **52 facial
units and 15 visemes (67 total)**; use this measured count rather than the 54
facial units currently stated in the export-copy documentation.

## Verification and scope

A fresh background Blender process created a 13,380-vertex human body with a
53-bone GameEngine rig, eyes and teeth. All 67 facial/speech targets loaded and
survived GLB export. Both blinks, jaw opening, both smile corners, and selected
speech targets have nonzero geometry deltas. Target interpolation to child
meshes ran successfully. A head-only Blender render was inspected.

Godot 4.7.2 headless/Dummy imported the GLB successfully: one 53-bone skeleton,
three skinned meshes, 67 body shapes, eight eye shapes and 12 teeth shapes.
The imported geometry and skin weights passed finite/range checks; jaw opening,
both blinks, both smile corners and `viseme_aa` had nonzero imported deltas.
The complete fixture has 34,048 triangles, including the stock teeth. This
confirms import capability, not a production geometry budget or styled result.

The exporter warned that it retained and normalized the four highest bone
influences per vertex and chose the first texture sampler where materials used
multiple image nodes. These require review during production adaptation.
This is an installation fixture, not an accepted court character or animation.

Local files (intentionally excluded from Git):

- ZIPs and installation manifest: `C:/Users/sjpur/Downloads/MPFB-court-assets/`
- Source, GLB, head render and verification JSON: the `verification/` subfolder.
- MPFB asset library: `C:/Users/sjpur/AppData/Roaming/Blender Foundation/Blender/5.2/extensions/.user/user_default/mpfb/data`
- Setup/check scripts and logs: `artifacts/mpfb*` in the court-face-richness worktree.

The installation fixture above remains separate from production. The production
adapter retains the game's existing rig and animation clips, maps native targets
to the court's face contract, fits existing hair, and replaces heads in all seven
original, legacy and era body bundles. Source NPZs, original brow/teeth textures,
licenses and provenance are committed under `assets/court_figures/mpfb_source/`.
See `docs/COURT_MPFB_HANDOFF.md` for regeneration, acceptance and remaining limits.

Blender 5.2's geometry-node hair editor and Rigify are outside this check:
[upcoming MPFB fixes](https://static.makehumancommunity.org/mpfb/releases/release_next.html)
explicitly address those paths. The verified path uses the GameEngine rig.
