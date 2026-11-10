shader_type canvas_item;
render_mode unshaded;
// COLOR already contains the sampled texture and vertex modulation in Godot.
// Discard only the near-transparent generated matte; do not multiply RGB twice.
void fragment() {
 if (texture(TEXTURE, UV).a < 0.12) discard;
}
