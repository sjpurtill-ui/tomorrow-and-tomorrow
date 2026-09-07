# City civilization flags

Worktree /Users/seanpurtill/Documents/Codex/tt-city-flags, branch codex/city-flags,
base 86f2971e6c1dd8fc73e710cc58ee7d69eaaad294. Task owns city-label rendering in
scripts/local_terrain.gd, scripts/city_map_identity.gd and the existing map-label
regression suite. local_terrain.gd is the only shared hotspot; no conflicts.

Each reported civilization receives a deterministic colored heraldic flag. All its
city labels and locator pins use that flag color. Flags sit beside the name with
fixed screen size at every distance, and extend the existing city click target.
The identity comes from reported controller, falling back to reported civilization;
unknown identity remains neutral. It does not consult hidden live occupation data.
Owned city labels use the selected founding banner and a legible hue drawn from it.
Flag textures are cached; refresh reuses sprite nodes and preserves aerial sizing.
No simulation or save format change. Rival flags are new procedural UI artwork;
this task does not change army relation colors or create a flag editor.

Clean isolated Godot import passes. Three targeted tests pass (0 errors/failures/
orphans), covering four distances, repeated normalization, flags/colors, cached
identity and reported control changes without replacing the city mesh, plus the
existing immediate intelligence summary. Logs /tmp/city-flags-import.log and
/tmp/city-flags-tests.log. Headless application data is isolated with Dummy audio.
