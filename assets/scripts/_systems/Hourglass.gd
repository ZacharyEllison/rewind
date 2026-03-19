## Hourglass
## XRTools-pickable rewind trigger. Grab it with the grip button; press trigger to rewind.
## Attach this script to a RigidBody3D node set up with XRToolsPickable.
## collision_layer must include layer 3 (pickable) so FunctionPickup can detect it.

extends XRToolsPickable

var _game_manager: Node = null
var _mesh_instance: MeshInstance3D = null


func _ready() -> void:
	super()
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	action_pressed.connect(_on_action_pressed)
	_build_mesh()


## Called by XRToolsPickable when the player presses trigger while holding this object.
func _on_action_pressed(_what) -> void:
	if not _game_manager:
		return
	if _game_manager.is_recording_active():
		_game_manager.stop_recording()
		_game_manager.trigger_rewind()
	elif not _game_manager.is_rewinding_active():
		_game_manager.start_new_attempt()
		_game_manager.start_recording()


## Build a simple procedural hourglass mesh (two cones tip-to-tip).
## Replace this with a real GLB model once one is available.
func _build_mesh() -> void:
	_mesh_instance = MeshInstance3D.new()
	var arr_mesh := ArrayMesh.new()

	# Parameters
	const SEGMENTS: int = 8
	const HALF_HEIGHT: float = 0.12   # half-height of each cone
	const BASE_RADIUS: float = 0.07   # wide end radius
	const NECK_RADIUS: float = 0.015  # narrow centre radius

	# Build both cones (upper apex up, lower apex down)
	for cone_idx in range(2):
		var sign := 1.0 if cone_idx == 0 else -1.0   # +1 = upper, -1 = lower
		var apex_y := sign * HALF_HEIGHT * 2.0        # tip of the cone
		var base_y := sign * NECK_RADIUS              # neck end

		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		var verts := PackedVector3Array()
		var normals := PackedVector3Array()

		for i in range(SEGMENTS):
			var a0 := TAU * i / SEGMENTS
			var a1 := TAU * (i + 1) / SEGMENTS
			var r: float = BASE_RADIUS if cone_idx == 0 else BASE_RADIUS

			# Triangle: apex + two base edge points
			var p_apex := Vector3(0.0, apex_y, 0.0)
			var p0 := Vector3(cos(a0) * r, base_y, sin(a0) * r)
			var p1 := Vector3(cos(a1) * r, base_y, sin(a1) * r)

			# Face normal (flat shading)
			var edge1 := p0 - p_apex
			var edge2 := p1 - p_apex
			var n := edge1.cross(edge2).normalized() * sign

			verts.append_array([p_apex, p0, p1])
			normals.append_array([n, n, n])

		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Glowing amber material (matches sand crystal aesthetic)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.6, 0.1, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0)
	mat.emission_energy_multiplier = 1.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for surf in range(arr_mesh.get_surface_count()):
		arr_mesh.surface_set_material(surf, mat)

	_mesh_instance.mesh = arr_mesh
	add_child(_mesh_instance)
