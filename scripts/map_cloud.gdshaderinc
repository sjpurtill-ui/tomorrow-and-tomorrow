// Cloud shadows on the land (codex/beauty-2), shared by the terrain and the
// plants on it. Include after map_palette.gdshaderinc (map_paper_noise).
// Uniforms come from scripts/map_ambience.gd, which pushes them to every map
// material whose shader declares `map_cloud`.

uniform vec4 map_cloud = vec4(0.0);
uniform float map_cloud_scale = 1.3;

// Toward the low north-west sun in the ground plane (as world_beauty WB_SUN_XZ).
const vec2 MAP_CLOUD_SUN_XZ = vec2(-0.7385, -0.6743);

// Cloud shadows cast on the land itself (map_cloud from map_ambience.gd:
// drift xy, cover, strength). The cloud deck sits about 1.2 km up; each
// point reads the cloud that stands between it and the low north-west sun,
// so a shadow slides over a hill the way a real one climbs it. Soft-edged,
// cool and faint (secondary to the land; codex/map-beauty), never a dark
// blot. Returns a colour multiplier.
vec3 map_cloud_shadow(vec2 world_xz, float height, vec4 cloud, float scale_km) {
	if (cloud.w <= 0.001) { return vec3(1.0); }
	// Low sun (about 31 degrees): horizontal reach per km of height is ~1.66.
	vec2 at = world_xz+MAP_CLOUD_SUN_XZ*max(1.2-height, 0.0)*1.66-cloud.xy;
	vec2 p = at/max(scale_km, 0.01);
	float n = map_paper_noise(p)*0.55+map_paper_noise(p*2.0+17.0)*0.28
		+map_paper_noise(p*4.0+41.0)*0.12+map_paper_noise(p*8.0+73.0)*0.05;
	float edge = 1.0-cloud.z;
	float c = smoothstep(edge-0.16, edge+0.24, n);
	return mix(vec3(1.0), vec3(0.89, 0.91, 0.96), c*clamp(cloud.w, 0.0, 1.0));
}
