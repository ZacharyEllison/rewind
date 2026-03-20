## GhostAppearance
## Applies the two-pass ghost shader (white fill + black outline) to every
## MeshInstance3D found in a given subtree.
##
## Usage (from GhostRobot._ready):
##   GhostAppearance.apply(self)
##
## The fill material uses next_pass to chain the outline material so that both
## passes are applied automatically by Godot's renderer without needing a
## duplicate mesh. This technique is compatible with the gl_compatibility
## renderer required for Meta Quest 3.

class_name GhostAppearance
extends RefCounted

const FILL_SHADER_PATH := "res://assets/shaders/ghost_fill.gdshader"
const OUTLINE_SHADER_PATH := "res://assets/shaders/ghost_outline.gdshader"

## Apply ghost materials to all MeshInstance3D nodes in [param root]'s subtree.
## [param outline_width] controls how thick the black outline appears (world units
## in view space; tune between 0.01 and 0.05).
static func apply(root: Node3D, outline_width: float = 0.025) -> void:
	var fill_shader: Shader = load(FILL_SHADER_PATH)
	var outline_shader: Shader = load(OUTLINE_SHADER_PATH)

	if fill_shader == null or outline_shader == null:
		push_error("GhostAppearance: could not load ghost shaders. Check paths.")
		return

	# Build the chained material once and reuse across all surfaces/meshes.
	var outline_mat := ShaderMaterial.new()
	outline_mat.shader = outline_shader
	outline_mat.set_shader_parameter("outline_width", outline_width)
	outline_mat.set_shader_parameter("outline_color", Color(1.0, 1.0, 1.0))

	var fill_mat := ShaderMaterial.new()
	fill_mat.shader = fill_shader
	fill_mat.set_shader_parameter("fill_color", Color(0.0, 0.0, 0.0))
	fill_mat.set_shader_parameter("fill_alpha", 0.85)
	# Chain: fill renders first (front faces), outline renders second (back faces).
	fill_mat.next_pass = outline_mat

	_apply_to_subtree(root, fill_mat)


static func _apply_to_subtree(node: Node, fill_mat: ShaderMaterial) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var surface_count := mesh_instance.get_surface_override_material_count()
		# If the mesh has no surfaces yet, override at index 0 as a fallback.
		if surface_count == 0:
			mesh_instance.set_surface_override_material(0, fill_mat)
		else:
			for i in range(surface_count):
				mesh_instance.set_surface_override_material(i, fill_mat)

	for child in node.get_children():
		_apply_to_subtree(child, fill_mat)
