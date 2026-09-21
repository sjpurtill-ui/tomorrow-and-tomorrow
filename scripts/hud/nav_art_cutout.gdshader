shader_type canvas_item;
render_mode unshaded;

// The approved atlas includes an olive paper background. Retain its gold
// pigment while allowing the sidebar (including selection) through the crop.
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float brightness = max(source.r, source.g);
	float gold = step(0.035, source.r - source.b);
	float pigment = smoothstep(0.33, 0.37, brightness) * gold;
	COLOR = vec4(source.rgb, source.a * pigment);
}
