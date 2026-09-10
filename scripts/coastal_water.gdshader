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

// This is the alternating triangle interpolation of TerrainPatchBuilder, not
// bilinear interpolation or a second noise field. Heights and distances are km.
float visible_ground(vec2 point) {
	vec2 cell = clamp(((point-terrain_grid.xy)/terrain_grid.z+0.5)*(terrain_grid.w-1.0),
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

void vertex() { world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }

void fragment() {
	vec2 point = world_position.xz;
	if (!regional_surface && terrain_grid.z>0.0 &&
		max(abs(point.x-terrain_grid.x),abs(point.y-terrain_grid.y))<terrain_grid.z*0.5) { discard; }
	vec2 uv = clamp(point/fog_world_size+0.5,vec2(0.0),vec2(1.0));
	float current_visibility = 1.0-smoothstep(30.0,38.0,distance(point,fog_current_origin));
	float visible = smoothstep(0.06,0.62,max(texture(discovery_mask,uv).r,current_visibility));
	float depth = 1.0;
	float surveyed_surface = 0.0;
	if (terrain_grid.z>0.0 && terrain_grid.w>=2.0) {
		float edge = max(abs(point.x-terrain_grid.x),abs(point.y-terrain_grid.y))/terrain_grid.z*2.0;
		if (edge<=1.0) {
			depth = max(sea_level-visible_ground(point),0.0);
			// The regional patch extends beyond the camera. Fade its *color* at the
			// outer margin; do not draw an invented shallow rim at a texture edge.
			surveyed_surface = 1.0-smoothstep(0.84,1.0,edge);
		}
	}
	float pixel_world = max(length(dFdx(point)),length(dFdy(point)));
	// At continental distances the streamed bathymetry covers less than the
	// view. Resolve to ocean color before its moving patch can read as a square.
	surveyed_surface *= 1.0-smoothstep(0.15,0.65,pixel_world);
	float wind_detail = 1.0-smoothstep(0.008,0.035,pixel_world);
	float ripple_detail = 1.0-smoothstep(0.0007,0.004,pixel_world);
	float time = TIME*wave_speed;
	float wind_a = dot(point,vec2(76.0,42.0))+sin(dot(point,vec2(9.7,-11.1)))*2.1-time*0.23;
	float wind_b = dot(point,vec2(-53.0,86.0))+sin(dot(point,vec2(-7.3,5.1)))*1.7+time*0.16;
	float ripple = dot(point,vec2(780.0,390.0))-time*0.55;
	vec2 normal_wave = vec2(cos(wind_a),sin(wind_b))*0.025*wind_detail;
	normal_wave += vec2(cos(ripple),sin(ripple*0.81))*0.012*ripple_detail;
	vec3 deep = vec3(0.027,0.085,0.13);
	vec3 shelf = vec3(0.065,0.195,0.23);
	vec3 shallows = vec3(0.18,0.285,0.26);
	vec3 water = mix(deep,shelf,exp(-depth/0.15)*surveyed_surface);
	water = mix(water,shallows,exp(-depth/0.012)*surveyed_surface);
	water *= 1.0+(sin(wind_a)*sin(wind_b))*0.012*wind_detail;
	// Only an actual shallow bed can produce a narrow wash. Filter it out before
	// it becomes a flickering white coastline at distant map scales.
	float wash = (1.0-smoothstep(0.0003,0.0015,depth))*surveyed_surface*ripple_detail;
	water = mix(water,vec3(0.39,0.43,0.38),wash*0.24);
	ALBEDO = mix(vec3(0.004,0.010,0.013),water,visible);
	NORMAL_MAP = vec3(normal_wave*visible,1.0)*0.5+0.5;
	ROUGHNESS = 0.44;
	SPECULAR = 0.18*visible;
}
