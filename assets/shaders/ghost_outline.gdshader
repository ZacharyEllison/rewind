// Ghost Outline Shader
// Renders back faces only, expanded outward along view-space normals, producing
// a solid black outline around the ghost mesh.
// Compatible with gl_compatibility renderer (Meta Quest 3 / mobile XR).
shader_type spatial;
render_mode unshaded, cull_front, blend_mix, depth_draw_opaque;

uniform float outline_width : hint_range(0.0, 0.1) = 0.025;
uniform vec3 outline_color : source_color = vec3(1.0, 1.0, 1.0);

void vertex() {
	// Transform vertex and normal into view space, then push outward.
	vec4 pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_normal = normalize(mat3(MODELVIEW_MATRIX) * NORMAL);
	pos.xyz += view_normal * outline_width;
	POSITION = PROJECTION_MATRIX * pos;
}

void fragment() {
	ALBEDO = outline_color;
	ALPHA = 1.0;
}
