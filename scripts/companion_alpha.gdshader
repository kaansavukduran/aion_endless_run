shader_type canvas_item;
render_mode unshaded;
// Generated pixel atlas includes near-zero alpha matte pixels; discard only
// those pixels at render time, preserving the original generated PNG bytes.
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (pixel.a < 0.12) discard;
	COLOR *= vec4(pixel.rgb, 1.0);
}
