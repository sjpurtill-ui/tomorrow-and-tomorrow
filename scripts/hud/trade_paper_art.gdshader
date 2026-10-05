shader_type canvas_item;
render_mode unshaded;

// Existing painted material sheets have a pale paper ground. Let the page's
// own paper show through that ground while retaining the coloured pigment.
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float ink = smoothstep(0.025, 0.22, distance(source.rgb, vec3(0.96, 0.925, 0.865)));
	COLOR = vec4(source.rgb, source.a * ink);
}
