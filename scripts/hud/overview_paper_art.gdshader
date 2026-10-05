shader_type canvas_item;
render_mode unshaded;

// The overview atlas's warm paper dissolves into either page palette.
// Its pigments remain; this does not change the source asset.
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float pigment = smoothstep(0.05, 0.20, distance(source.rgb, vec3(0.952, 0.896, 0.791)));
	COLOR = vec4(source.rgb, source.a * pigment);
}
