// Ghost Fill Shader
// Renders the front faces of the ghost mesh with a white semi-transparent fill.
// Compatible with gl_compatibility renderer (Meta Quest 3 / mobile XR).
shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_opaque;

uniform vec3 fill_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float fill_alpha : hint_range(0.0, 1.0) = 0.85;

void fragment() {
	ALBEDO = fill_color;
	ALPHA = fill_alpha;
}
