shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
varying vec2 ground;
float grain(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise_at(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(grain(i),grain(i+vec2(1,0)),f.x),mix(grain(i+vec2(0,1)),grain(i+vec2(1,1)),f.x),f.y);
}
void vertex(){ground=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
	float footprint=max(length(dFdx(ground)),length(dFdy(ground)));
	float brush=mix(noise_at(ground*29.0),0.5,smoothstep(0.008,0.08,footprint));
	float broad=noise_at(ground*5.0);
	ALBEDO=COLOR.rgb*(0.87+brush*0.15);
	// Preserve the painted form. Grain modulates its surface rather than
	// erasing most of a field or scar into the ordinary grass texture.
	ALPHA=COLOR.a*(0.76+0.24*smoothstep(0.12,0.88,broad*0.55+brush*0.45));
}
