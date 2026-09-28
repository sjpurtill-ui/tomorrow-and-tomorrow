shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D discovery_mask : source_color, filter_linear;
uniform vec2 fog_world_size = vec2(40075.0, 20004.0);
uniform vec2 fog_current_origin = vec2(0.0);
uniform float sea_level = 0.0;
uniform float wave_speed = 1.0;
uniform bool regional_surface = false;
varying vec3 world_position;
varying vec3 relative_position;
varying vec2 surface_position;
uniform vec2 surface_origin = vec2(0.0);
uniform vec4 wave_phase = vec4(0.0);
uniform vec2 ripple_phase = vec2(0.0);
#include "res://scripts/coast_mask.gdshaderinc"
#include "res://scripts/map_palette.gdshaderinc"
#include "res://scripts/map_coast.gdshaderinc"
#include "res://scripts/water_beauty.gdshaderinc"
#include "res://scripts/world_beauty.gdshaderinc"
#include "res://scripts/map_chart.gdshaderinc"

float charted_at(vec2 xz) {
	vec2 uv = clamp(xz/fog_world_size+0.5,vec2(0.0),vec2(1.0));
	return max(texture(discovery_mask,uv).r,1.0-smoothstep(30.0,38.0,distance(xz,fog_current_origin)));
}

void vertex() {
	world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	relative_position = world_position-CAMERA_POSITION_WORLD;
	surface_position = world_position.xz-surface_origin;
}

void fragment() {
	// Before any discard (derivatives are undefined once a quad diverges).
	float pixel_world = max(length(dFdx(relative_position.xz)),length(dFdy(relative_position.xz)));
	vec2 point = surface_position;
	vec2 local_grid = terrain_grid.xy-surface_origin;
	if (!regional_surface && terrain_grid.z>0.0 &&
		max(abs(point.x-local_grid.x),abs(point.y-local_grid.y))<terrain_grid.z*0.5) { discard; }
	// Land and water agree across LODs: beyond the streamed patch, and where its
	// soft margin gives way, the macro raster decides the shoreline, exactly as
	// it does for the coarse planet mesh (which draws there).
	if (coast_mask_ready()) {
		bool raster_decides = !regional_surface
			|| (terrain_grid.z>0.0 && coast_patch_yields(world_position.xz, vec4(terrain_grid.xy, terrain_grid.z, 1.0)));
		if (raster_decides && coast_mask_height(world_position.xz) > 0.0) { discard; }
	}
	// Over the streamed patch the shoreline is where that patch's own triangles
	// cross sea level. Decide it here rather than by depth test: a low shore
	// lies within depth precision of the sea plane, and the two fought in
	// combed stripes along every flat coast.
	// Where cells are large on screen the shore is the smooth contour shared
	// with the patch's land (map_coast.gdshaderinc), not the triangles' chords.
	float patch_ground = sea_level;
	bool over_patch = coast_patch_ready() && coast_patch_contains(point-local_grid);
	if (over_patch) { patch_ground = coast_patch_ground(point-local_grid, pixel_world, sea_level); }
	if (regional_surface && over_patch
		&& !coast_patch_yields(world_position.xz, vec4(terrain_grid.xy, terrain_grid.z, 1.0))
		&& patch_ground > sea_level) { discard; }
	float charted = charted_at(world_position.xz);
	float visible = smoothstep(0.06,0.62,charted);
	// Uncharted sea is the same blank vellum as uncharted land, and the same
	// frontier ink runs across the coast without a break.
	vec3 unknown_surface = map_chart_paper(world_position.xz,CAMERA_POSITION_WORLD.y,pixel_world,fog_current_origin,SCREEN_UV);
	if (charted>0.02 && charted<0.75) {
		float step_km = fog_world_size.x/2048.0;
		vec2 slope_per_km = vec2(charted_at(world_position.xz+vec2(step_km,0.0))-charted,charted_at(world_position.xz+vec2(0.0,step_km))-charted)/step_km;
		vec3 frontier = map_frontier(charted,1.0/max(length(slope_per_km)*pixel_world,0.00001));
		float frontier_scale = smoothstep(0.015,0.20,pixel_world);
		unknown_surface = mix(unknown_surface,MAP_SEPIA,frontier.y*frontier_scale*0.38);
		unknown_surface = mix(unknown_surface,MAP_INK,frontier.x*frontier_scale*0.85);
		visible = mix(visible,frontier.z,frontier_scale)*(1.0-frontier.x*frontier_scale*0.85);
	}
	float depth = 1.0;
	float surveyed_surface = 0.0;
	float patch_weight = 0.0;
	float patch_depth = 1.0;
	if (terrain_grid.z>0.0 && terrain_grid.w>=2.0) {
		float edge = max(abs(point.x-local_grid.x),abs(point.y-local_grid.y))/terrain_grid.z*2.0;
		if (edge<=1.0) {
			patch_depth = max(sea_level-patch_ground,0.0);
			// The regional patch extends beyond the camera. Fade its *color* at the
			// outer margin; do not draw an invented shallow rim at a texture edge.
			patch_weight = 1.0-smoothstep(0.70,0.95,edge);
		}
	}
	if (coast_mask_ready()) {
		// Beyond the streamed bathymetry the macro raster supplies the shelf, so
		// the coast keeps its shallows instead of turning deep at a square edge.
		depth = mix(max(sea_level-coast_mask_height(world_position.xz),0.0),patch_depth,patch_weight);
		surveyed_surface = 1.0;
	} else {
		depth = patch_depth;
		surveyed_surface = patch_weight;
	}
	// At continental distances the streamed bathymetry covers less than the
	// view. Resolve to ocean color before its moving patch can read as a square.
	surveyed_surface *= 1.0-smoothstep(0.15,0.65,pixel_world);
	float wind_detail = 1.0-smoothstep(0.008,0.035,pixel_world);
	float ripple_detail = 1.0-smoothstep(0.0007,0.004,pixel_world);
	// Three oblique wave trains avoid the conspicuous diagonal crosshatch that
	// read as a procedural overlay at 10,000 feet. Their amplitude is deliberately
	// restrained: satellite-scale water should read primarily through color.
	vec2 normal_wave = vec2(0.0);
	if (wind_detail>0.0) {
		float time = TIME*wave_speed;
		float wind_a = dot(point,vec2(71.0,37.0))+wave_phase.x+sin(dot(point,vec2(8.3,-10.7))+wave_phase.z)*2.1-time*0.23;
		float wind_b = dot(point,vec2(-43.0,79.0))+wave_phase.y+sin(dot(point,vec2(-6.1,4.7))+wave_phase.w)*1.7+time*0.16;
		float wind_c = dot(point,vec2(29.0,-61.0))+wave_phase.z+sin(dot(point,vec2(3.9,7.1))+wave_phase.x)*1.3-time*0.11;
		normal_wave = vec2(cos(wind_a)+0.55*sin(wind_c),sin(wind_b)-0.45*cos(wind_c))*0.013*wind_detail;
		if (ripple_detail>0.0) {
			float ripple = dot(point,vec2(780.0,390.0))+ripple_phase.x-time*0.55;
			float ripple_b = dot(point,vec2(631.8,315.9))+ripple_phase.y-time*0.4455;
			normal_wave += vec2(cos(ripple),sin(ripple_b))*0.006*ripple_detail;
		}
	}
	// Earth-observation water is primarily a depth image: open ocean remains
	// blue-black, the continental shelf shifts blue-green, and only optically
	// shallow water takes on the mineral colour of its bed.
	// The unstreamed ocean still needs geographic scale. Two very broad, static
	// basin terms keep continent views from becoming a single flat paint fill;
	// they are stable in world space, resolve to an almost constant local tint at
	// coastal zoom, and add no texture bandwidth or animation cost.
	float basin_field=clamp(0.50
		+0.28*sin(dot(world_position.xz,vec2(0.0011,0.0003))+0.7)
		+0.22*sin(dot(world_position.xz,vec2(-0.0004,0.0017))-1.1),0.0,1.0);
	float polar_water=clamp(abs(world_position.z)/(fog_world_size.y*0.5),0.0,1.0);
	// Painted water (world_beauty): a deep slate-blue sea lifting through a
	// green-slate shelf to clear, pale shallows over a sandy bed, as a
	// watercolourist lays a coast. Muted, never cyan.
	vec3 deep = mix(vec3(0.072,0.122,0.150),vec3(0.086,0.140,0.162),basin_field);
	deep=mix(deep,vec3(0.092,0.135,0.152),polar_water*0.16);
	vec3 shelf = vec3(0.100,0.178,0.182);
	vec3 shallows = vec3(0.180,0.300,0.270);
	vec3 bed = vec3(0.330,0.330,0.245);
	vec3 water = mix(deep,shelf,exp(-depth/0.16)*surveyed_surface);
	water = mix(water,shallows,exp(-depth/0.022)*surveyed_surface);
	// Only the last metres show the bed through clear water.
	// Muted and a little green, so a shallow lagoon never reads as grey sand.
	water = mix(water,mix(bed,shallows,0.35),exp(-depth/0.0024)*surveyed_surface*0.26);
	// Broad, static suspended-sediment variation gives shallow coasts the
	// irregular mineral tint visible in aerial imagery without animating the bed.
	float sediment = 0.0;
	if (surveyed_surface>0.0 && depth<0.15) {
		// World-anchored value noise. The former pair of crossed sine waves drew a
		// regular ~4 km lattice of blotches over every shelf, which read as a
		// cloud texture laid across the sea at regional zoom.
		float sediment_field = coast_feather_noise(world_position.xz*0.23+vec2(41.0,-17.0));
		// Plumes are a close-view cue; at regional footprints they only mottle.
		sediment = exp(-depth/0.034)*surveyed_surface*smoothstep(0.30,0.75,sediment_field)
			*(1.0-smoothstep(0.03,0.12,pixel_world));
	}
	// Ponds, meres and closed lagoons (water_beauty.gdshaderinc) are still
	// water: no bed glare, sediment, surf or water-lines of an open shore.
	float pond = 0.0;
	if (over_patch && patch_weight>0.0 && patch_depth<0.03) {
		pond = wbw_enclosure(point-local_grid, pixel_world, sea_level)*patch_weight;
	}
	float open_shore = 1.0-pond;
	sediment *= open_shore;
	water = mix(water,vec3(0.315,0.335,0.245),sediment*0.42);
	// Only an actual shallow bed can produce a narrow wash. Filter it out before
	// it becomes a flickering white coastline at distant map scales.
	float wash = (1.0-smoothstep(0.00025,0.0012,depth))*surveyed_surface*ripple_detail;
	water = mix(water,vec3(0.49,0.50,0.41),wash*0.20*open_shore);
	// Engraved water-lines, as old charts drew them: three fine pale lines
	// following the shore at widening screen-pixel spacing, fading seaward.
	float shore_px = depth/max(fwidth(depth),0.0000001);
	float water_lines = 0.0;
	for (int k = 0; k < 3; k++) {
		float at = 4.0+float(k*(k+3))*1.7;
		water_lines = max(water_lines,(1.0-smoothstep(0.30,1.05,abs(shore_px-at)))*(1.0-float(k)*0.30));
	}
	water_lines *= smoothstep(0.003,0.02,pixel_world)*(1.0-smoothstep(0.35,0.95,pixel_world));
	// Only where the bed actually shelves toward a shore: over a flat shallow
	// bank every faint undulation would otherwise draw its own ring.
	water_lines *= smoothstep(0.0015,0.006,fwidth(depth)/max(pixel_world,0.000001));
	water_lines *= open_shore;
	water = mix(water,vec3(0.34,0.37,0.31),water_lines*0.60);
	// Surf: a thin broken pale line at the water's edge and a fainter second
	// one a few pixels out where the swell first breaks, in screen pixels so it
	// stays a painted line at every close zoom. Settlement and valley zooms only.
	float surf_detail = (1.0-smoothstep(0.002,0.014,pixel_world))*surveyed_surface
		*smoothstep(0.0015,0.006,fwidth(depth)/max(pixel_world,0.000001))*open_shore;
	if (surf_detail>0.0) {
		float breakup = coast_feather_noise(world_position.xz/max(pixel_world*9.0,0.000001)+vec2(-13.0,29.0));
		float swash = 1.0-smoothstep(0.6,2.2,shore_px);
		float breaker = 1.0-smoothstep(0.35,1.2,abs(shore_px-6.5));
		float foam = max(swash*smoothstep(0.12,0.40,breakup),breaker*smoothstep(0.40,0.70,breakup)*0.50);
		water = mix(water,vec3(0.74,0.75,0.70),foam*surf_detail*0.85);
	}
	float view_slant = length(relative_position.xz)/max(abs(relative_position.y),0.001);
	if (pond>0.0) {
		// Distance from the pond's own edge, in screen pixels, from the
		// streamed surface (the water's depth there is only a metre or two).
		float pond_px = patch_depth/max(fwidth(patch_depth),0.0000001);
		water = mix(water,wbw_still_water(pond_px,view_slant,SCREEN_UV,1.0-smoothstep(0.004,0.03,pixel_world)),pond);
	}
	float altitude_haze = clamp(log(max(pixel_world,0.004)/0.004)/log(250.0),0.0,1.0)*0.26;
	float slant_haze = smoothstep(0.15,1.2,view_slant)*smoothstep(0.03,0.35,pixel_world);
	// The same parchment haze as the land, so the coast does not change key.
	water = map_haze(water,clamp(altitude_haze*0.55+slant_haze*0.14,0.0,0.22));
	// At chart zoom the sea is a lighter slate wash on the page, not ink.
	water = mix(water,vec3(0.150,0.225,0.228),smoothstep(0.20,1.2,pixel_world)*0.70);
	// A gentle sheen, brightest toward the low north-west sun (upper left),
	// in place of a specular glint a straight-down view can never see.
	float sheen = smoothstep(0.95,0.0,length((SCREEN_UV-vec2(0.08,0.02))*vec2(1.0,1.25)));
	water *= 1.0+sheen*0.16*vec3(1.05,1.0,0.90);
	// From the regional view outward the sea is the chart's pale wash on the
	// same paper as the land (map_chart.gdshaderinc), crossfaded by view scale.
	float mc_w = mc_chart_weight(mc_design_km(relative_position,PROJECTION_MATRIX));
	vec3 chart_sea = mc_w>0.0 ? mc_chart_sea(depth,world_position.xz,CAMERA_POSITION_WORLD.y) : vec3(0.0);
	ALBEDO = water*visible*(1.0-mc_w);
	// A chart's sea is a pale slate wash on the page, legible in any light:
	// part of its colour is carried as emission so low sun cannot sink it to black.
	EMISSION = unknown_surface*(1.0-visible)+mix(water*0.55,chart_sea,mc_w)*visible;
	NORMAL_MAP = vec3(normal_wave*visible*(1.0-mc_w),1.0)*0.5+0.5;
	ROUGHNESS = mix(0.48,0.38,wind_detail);
	SPECULAR = 0.14*visible*(1.0-mc_w);
}
