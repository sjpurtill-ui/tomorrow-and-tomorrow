shader_type spatial;
render_mode unshaded, specular_disabled, blend_mix, cull_disabled, depth_draw_never;
// The world river and its tributaries (local_terrain._build_river_network).
// Two meshes share this shader: RiverWater (the channel) and RiverBanks (the
// riparian margin, wider). Close up they are a painted ribbon of water between
// muddy banks. At chart scale, once a pixel spans tens of metres, they become
// the map's water ink (codex/map-3): a blue-slate stroke held in screen pixels
// that widens downstream and, on the broad lower reaches, opens into two inked
// banks around a pale water fill; the banks mesh becomes a soft water tint with
// one fine parallel water-line on the larger rivers. Where the river reaches
// the sea its ink gives way at the same shoreline the coastal water draws.
//
// Vertex inputs: UV.x across (0/1), UV.y half width (km), NORMAL the outward
// side, UV2.x signed bend, UV2.y source cap opacity, COLOR the reach tint,
// CUSTOM0.x downstream fraction (0 at the source, 1 at the mouth or join),
// CUSTOM0.y 1 for the trunk river and 0 for a tributary, CUSTOM0.z the scales
// a reach is drawn at: 0 all, 1 close up only (a tributary's surveyed course),
// 2 chart scale only (its smoothed line).
uniform sampler2D discovery_mask : source_color, filter_linear;
uniform vec2 fog_world_size=vec2(40075.0,20004.0);
uniform vec2 fog_current_origin=vec2(0.0);
uniform float resource_emphasis=0.0;
uniform bool river_water=false;
// Chart ink half width, in design pixels (1/1080 of the view height), of a
// full-flow reach before the downstream swell. 0 keeps the ribbon only.
uniform float chart_half_px=0.0;
uniform float chart_reference_half=0.105;
// The banks mesh at chart scale: how far the water tint reaches past the ink.
uniform float chart_tint_px=0.0;
#include "res://scripts/coast_mask.gdshaderinc"
#include "res://scripts/map_coast.gdshaderinc"

varying vec3 world_position;
varying float chart_weight;
varying float chart_coverage;
varying float chart_width_px;
varying float ink_half_px;
varying float trunk_flow;
varying float scale_role;

float stroke_scale(float downstream, float trunk) {
	// The trunk swells from a firm line in its upper reaches to a broad lower
	// river; a tributary gathers from a thread at its spring to its join.
	return trunk>0.5 ? mix(0.80,1.65,pow(downstream,0.8)) : mix(0.50,0.95,downstream);
}

void vertex(){
	float half_width=max(UV.y,0.0);
	vec3 side=vec3(NORMAL.x,0.0,NORMAL.z);
	side=dot(side,side)>0.0?normalize(side):vec3(0.0);
	vec3 centre=VERTEX-side*half_width;
	vec4 clip=PROJECTION_MATRIX*(MODELVIEW_MATRIX*vec4(centre,1.0));
	float km_per_px=2.0*abs(clip.w)/max(abs(PROJECTION_MATRIX[1][1])*1080.0,0.0001);
	chart_weight=smoothstep(0.010,0.040,km_per_px);
	float flow=pow(clamp(half_width/chart_reference_half,0.0,1.0),0.35);
	float downstream=clamp(CUSTOM0.x,0.0,1.0);
	trunk_flow=CUSTOM0.y>0.5 ? downstream : 0.0;
	scale_role=CUSTOM0.z;
	float ink_half=chart_half_px*flow*stroke_scale(downstream,CUSTOM0.y)*km_per_px;
	// Narrower than this a line only shimmers; thinner flow fades instead.
	float min_half=0.85*km_per_px;
	// Three quarters of a pixel beyond the ink leaves room for its soft rim.
	float chart_half=max(ink_half,min_half)+(chart_tint_px+0.75)*km_per_px;
	float drawn_half=chart_half_px>0.0?mix(half_width,max(half_width,chart_half),chart_weight):half_width;
	chart_coverage=chart_half_px>0.0?clamp(max(ink_half,half_width)/min_half,0.0,1.0):1.0;
	chart_width_px=2.0*drawn_half/max(km_per_px,0.000001);
	ink_half_px=max(ink_half,min_half)/max(km_per_px,0.000001);
	VERTEX=centre+side*drawn_half;
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	// Lift the chart line a pixel or two clear of the terrain it is drawn on.
	float chart_lift=chart_weight*1.5*km_per_px;
	vec2 rel=world_position.xz-terrain_grid.xy;
	if(coast_patch_ready() && max(abs(rel.x),abs(rel.y))<terrain_grid.z*0.49){
		float spread;
		float ground=coast_patch_triangle(rel,spread);
		// Seen obliquely, a line pinned to every coarse cell of relief kinks where
		// it crosses a slope. At chart scale it rides the smooth surface through
		// the same heights instead, raised to stay clear of the cell's chords.
		float chart_ground=max(ground,coast_patch_smooth(rel)+spread*0.25);
		VERTEX.y=mix(ground,chart_ground,chart_weight)+(river_water?0.0037:0.0021);
	}
	VERTEX.y+=chart_lift;
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}

float river_noise(vec2 p){
	vec2 i=floor(p),f=fract(p);
	f=f*f*(3.0-2.0*f);
	float a=fract(sin(dot(i,vec2(127.1,311.7)))*43758.5453);
	float b=fract(sin(dot(i+vec2(1.0,0.0),vec2(127.1,311.7)))*43758.5453);
	float c=fract(sin(dot(i+vec2(0.0,1.0),vec2(127.1,311.7)))*43758.5453);
	float d=fract(sin(dot(i+vec2(1.0,1.0),vec2(127.1,311.7)))*43758.5453);
	return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}

void fragment(){
	vec2 uv=clamp(world_position.xz/fog_world_size+vec2(0.5),vec2(0.0),vec2(1.0));
	float current_visibility=1.0-smoothstep(30.0,38.0,distance(world_position.xz,fog_current_origin));
	float discovered=smoothstep(0.08,0.58,max(texture(discovery_mask,uv).r,current_visibility));
	float edge=min(UV.x,1.0-UV.x)*2.0;
	float footprint=max(length(dFdx(world_position.xz)),length(dFdy(world_position.xz)));
	// Ribbon (close up) --------------------------------------------------
	float bank_detail=1.0-smoothstep(0.015,0.090,footprint);
	float water_detail=1.0-smoothstep(0.006,0.045,footprint);
	float bank_mass=river_noise(world_position.xz*5.5);
	float bank_grain=river_noise(world_position.xz*110.0);
	float shore_variation=((bank_mass-0.5)*0.38+(bank_grain-0.5)*0.055)*bank_detail;
	float coverage=smoothstep(0.01,river_water?0.16:0.65,edge+shore_variation);
	// Positive curvature turns toward +side (UV.x=1); bars belong there.
	float inside_bend=max(0.0,(UV.x*2.0-1.0)*UV2.x);
	float shoal_width=0.45+inside_bend*0.55;
	float shallows=1.0-smoothstep(0.03,shoal_width,edge+shore_variation);
	float broad_turbidity=river_noise(world_position.xz*0.72);
	float ripple=(river_noise(world_position.xz*19.0)-0.5)*0.006*water_detail;
	vec3 deep_water=mix(vec3(0.025,0.082,0.088),vec3(0.045,0.105,0.098),broad_turbidity);
	vec3 silty_water=mix(vec3(0.19,0.175,0.105),vec3(0.125,0.155,0.105),broad_turbidity);
	vec3 water=mix(deep_water,silty_water,shallows*0.58)+vec3(ripple);
	float exposed_bar=inside_bend*(1.0-smoothstep(0.04,0.28,edge))*bank_detail;
	water=mix(water,vec3(0.38,0.345,0.245)*(0.94+bank_grain*0.12),exposed_bar*0.85);
	float bank_margin=smoothstep(0.30,0.50,edge)*(1.0-smoothstep(0.68,0.96,edge));
	vec3 bank=mix(COLOR.rgb,vec3(0.285,0.255,0.17),bank_margin*(0.30+inside_bend*0.46)*bank_detail);
	// UV2.y feathers the spring/source cap; normal reaches remain opaque.
	float riparian_patch=mix(1.0,0.38+river_noise(world_position.xz*0.42)*0.62,bank_detail);
	float ribbon_alpha=COLOR.a*discovered*coverage*UV2.y*(river_water?1.0:riparian_patch);
	vec3 ribbon=river_water?water:bank;
	// Chart ink ------------------------------------------------------------
	float half_px=chart_width_px*0.5;
	float from_centre_px=abs(UV.x*2.0-1.0)*half_px;
	float ink_edge_px=ink_half_px-from_centre_px;
	vec3 chart_colour;
	float chart_alpha;
	if(river_water){
		// A firm blue-slate line; broad reaches open into two inked banks
		// around a pale water fill, as an engraver draws a lower river.
		// Linear colour: ink #2B4A57, fill #6F929A.
		vec3 ink=vec3(0.024,0.069,0.095);
		vec3 fill=vec3(0.159,0.288,0.323);
		float opened=smoothstep(2.0,2.9,ink_half_px);
		float bank_line=1.0-smoothstep(0.75,1.45,ink_edge_px);
		chart_colour=mix(ink,mix(fill,ink,bank_line),opened);
		chart_alpha=0.95*smoothstep(-0.55,0.55,ink_edge_px);
	}else{
		// A soft water tint either side of the ink, fading into the land, and on
		// the larger rivers a fine water-line running parallel to the bank.
		float beyond=max(from_centre_px-ink_half_px,0.0);
		float tint_reach=max(chart_tint_px,0.001);
		float tint=(1.0-smoothstep(0.0,tint_reach,beyond))*0.34;
		float line_offset=2.1+ink_half_px*0.15;
		float water_line=(1.0-smoothstep(0.30,0.85,abs(beyond-line_offset)))*smoothstep(0.35,0.70,max(trunk_flow,ink_half_px/3.4))*0.50;
		// Linear colour: tint #6F939B, water-line #3E5F6B.
		chart_colour=mix(vec3(0.159,0.291,0.330),vec3(0.048,0.114,0.147),water_line/max(tint+water_line,0.001));
		chart_alpha=max(tint,water_line)*smoothstep(0.0,0.6,half_px-from_centre_px);
	}
	// The sea takes over where the coastal water draws its shoreline.
	float land=1.0;
	vec2 rel=world_position.xz-terrain_grid.xy;
	if(coast_patch_ready() && coast_patch_contains(rel)){
		land=smoothstep(-0.0015,0.0015,coast_patch_ground(rel,footprint,0.0));
	}
	chart_alpha*=discovered*UV2.y*chart_coverage*land;
	vec3 surface=mix(ribbon,chart_colour,chart_weight);
	ALBEDO=mix(surface,vec3(0.10,0.31,0.34),resource_emphasis*0.35*(river_water?1.0:0.0));
	float scale_fade=1.0;
	if(scale_role>1.5){ scale_fade=smoothstep(0.35,0.65,chart_weight); }
	else if(scale_role>0.5){ scale_fade=1.0-smoothstep(0.35,0.65,chart_weight); }
	ALPHA=mix(ribbon_alpha,chart_alpha,chart_weight)*scale_fade;
}
