shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D discovery_mask : source_color, filter_linear;
uniform vec2 fog_world_size = vec2(40075.0, 20004.0);
uniform vec2 fog_current_origin = vec2(0.0);
uniform sampler2D terrain_heights : filter_nearest, repeat_disable;
uniform vec4 terrain_grid = vec4(0.0);
uniform float sea_level = 0.0;
uniform float wave_speed = 1.0;
uniform bool regional_surface = false;
varying vec3 world_position;
varying vec3 relative_position;
varying vec2 surface_position;
uniform vec2 surface_origin = vec2(0.0);
uniform vec4 wave_phase = vec4(0.0);
uniform vec2 ripple_phase = vec2(0.0);

// This is the alternating triangle interpolation of TerrainPatchBuilder, not
// bilinear interpolation or a second noise field. Heights and distances are km.
float visible_ground(vec2 point) {
	vec2 cell = clamp(((point-(terrain_grid.xy-surface_origin))/terrain_grid.z+0.5)*(terrain_grid.w-1.0),
		vec2(0.0), vec2(terrain_grid.w-1.001));
	ivec2 base = ivec2(floor(cell));
	vec2 f = fract(cell);
	float a = texelFetch(terrain_heights, base, 0).r;
	float b = texelFetch(terrain_heights, base+ivec2(1,0), 0).r;
	float c = texelFetch(terrain_heights, base+ivec2(1,1), 0).r;
	float d = texelFetch(terrain_heights, base+ivec2(0,1), 0).r;
	if (mod(float(base.x+base.y),2.0)<1.0) {
		return f.x>=f.y ? a+(b-a)*f.x+(c-b)*f.y : a+(c-d)*f.x+(d-a)*f.y;
	}
	return f.x+f.y<=1.0 ? a+(b-a)*f.x+(d-a)*f.y : c+(d-c)*(1.0-f.x)+(b-c)*(1.0-f.y);
}

void vertex() {
	world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	relative_position = world_position-CAMERA_POSITION_WORLD;
	surface_position = world_position.xz-surface_origin;
}

void fragment() {
	vec2 point = surface_position;
	vec2 local_grid = terrain_grid.xy-surface_origin;
	if (!regional_surface && terrain_grid.z>0.0 &&
		max(abs(point.x-local_grid.x),abs(point.y-local_grid.y))<terrain_grid.z*0.5) { discard; }
	vec2 uv = clamp(world_position.xz/fog_world_size+0.5,vec2(0.0),vec2(1.0));
	float current_visibility = 1.0-smoothstep(30.0,38.0,distance(world_position.xz,fog_current_origin));
	float visible = smoothstep(0.06,0.62,max(texture(discovery_mask,uv).r,current_visibility));
	float depth = 1.0;
	float surveyed_surface = 0.0;
	if (terrain_grid.z>0.0 && terrain_grid.w>=2.0) {
		float edge = max(abs(point.x-local_grid.x),abs(point.y-local_grid.y))/terrain_grid.z*2.0;
		if (edge<=1.0) {
			depth = max(sea_level-visible_ground(point),0.0);
			// The regional patch extends beyond the camera. Fade its *color* at the
			// outer margin; do not draw an invented shallow rim at a texture edge.
			surveyed_surface = 1.0-smoothstep(0.84,1.0,edge);
		}
	}
	float pixel_world = max(length(dFdx(relative_position.xz)),length(dFdy(relative_position.xz)));
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
	vec3 deep = vec3(0.024,0.083,0.132);
	vec3 shelf = vec3(0.045,0.162,0.215);
	vec3 shallows = vec3(0.135,0.285,0.265);
	vec3 water = mix(deep,shelf,exp(-depth/0.19)*surveyed_surface);
	water = mix(water,shallows,exp(-depth/0.018)*surveyed_surface);
	// Broad, static suspended-sediment variation gives shallow coasts the
	// irregular mineral tint visible in aerial imagery without animating the bed.
	float sediment = 0.0;
	if (surveyed_surface>0.0 && depth<0.15) {
		float sediment_field = 0.5+0.28*sin(dot(point,vec2(1.7,0.8))+wave_phase.z)
			+0.22*sin(dot(point,vec2(-0.55,1.25))+wave_phase.w);
		sediment = exp(-depth/0.034)*surveyed_surface*clamp(sediment_field,0.0,1.0);
	}
	water = mix(water,vec3(0.315,0.335,0.245),sediment*0.42);
	// Only an actual shallow bed can produce a narrow wash. Filter it out before
	// it becomes a flickering white coastline at distant map scales.
	float wash = (1.0-smoothstep(0.00025,0.0012,depth))*surveyed_surface*ripple_detail;
	water = mix(water,vec3(0.49,0.50,0.41),wash*0.20);
	float altitude_haze = smoothstep(0.65,5.0,pixel_world);
	float view_slant = length(relative_position.xz)/max(abs(relative_position.y),0.001);
	float slant_haze = smoothstep(0.15,1.2,view_slant)*smoothstep(0.03,0.35,pixel_world);
	water = mix(water,vec3(0.17,0.245,0.28),clamp(altitude_haze*0.13+slant_haze*0.13,0.0,0.22));
	ALBEDO = water*visible;
	EMISSION = vec3(0.006,0.012,0.014)*(1.0-visible);
	NORMAL_MAP = vec3(normal_wave*visible,1.0)*0.5+0.5;
	ROUGHNESS = mix(0.48,0.38,wind_detail);
	SPECULAR = 0.14*visible;
}
