shader_type canvas_item;
render_mode unshaded;
// COLOR already contains the sampled texture and vertex modulation in Godot.
// Discard only the near-transparent generated matte; do not multiply RGB twice.
uniform bool weapon_red = false;
uniform vec4 weapon_uv = vec4(0.0, 0.0, 1.0, 1.0);
void fragment() {
 if (texture(TEXTURE, UV).a < 0.12) discard;
 // The upgrade changes only cyan pistol insets, never the hero's eyes/gills.
 if (weapon_red && UV.x >= weapon_uv.x && UV.y >= weapon_uv.y && UV.x <= weapon_uv.z && UV.y <= weapon_uv.w && COLOR.g > COLOR.r * 1.25 && COLOR.b > COLOR.r * 1.25) {
  float light = max(COLOR.g, COLOR.b);
  COLOR.rgb = vec3(0.25 + light * 0.75, 0.06 + light * 0.18, 0.10 + light * 0.22);
 }
}
