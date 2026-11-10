shader_type canvas_item;
// Display the owner's unchanged companion sheets on a 48px pixel grid.
uniform vec2 sheet_size = vec2(1024.0, 864.0);
uniform float cell = 5.3333333;
void fragment() {
	vec2 uv = (floor(UV * sheet_size / cell) + 0.5) * cell / sheet_size;
	vec4 c = texture(TEXTURE, uv);
	c.rgb = floor(c.rgb * 15.0 + 0.5) / 15.0;
	COLOR *= c;
}
