## Hourglass
## XRTools-pickable hourglass used by the player-following pedestal rewind rig.
## collision_layer must include layer 3 (pickable) so FunctionPickup can detect it.

class_name Hourglass
extends XRToolsPickable

@export var upside_down_dot_threshold: float = -0.7
@export var return_delay: float = 0.75

var _mesh_instance: MeshInstance3D = null
var _return_timer: Timer = null
var _pending_return_anchor: Node3D = null


func _ready() -> void:
	super()
	add_to_group("hourglass_pickable")
	_build_mesh()
	_build_collision()
	_ensure_return_timer()
	picked_up.connect(_on_picked_up)


func is_upside_down() -> bool:
	return global_transform.basis.y.dot(Vector3.UP) <= upside_down_dot_threshold


func snap_to_anchor(anchor: Node3D) -> void:
	if not anchor:
		return
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true
	freeze = true
	global_transform = anchor.global_transform


func reset_to_anchor(anchor: Node3D) -> void:
	cancel_pending_return()
	snap_to_anchor(anchor)


func schedule_return(anchor: Node3D) -> void:
	if not anchor:
		return
	_pending_return_anchor = anchor
	if is_picked_up():
		return
	_return_timer.start(return_delay)


func cancel_pending_return() -> void:
	_pending_return_anchor = null
	if _return_timer:
		_return_timer.stop()


## Build a simple procedural hourglass mesh (two cones tip-to-tip).
## Replace this with a real GLB model once one is available.
func _build_mesh() -> void:
	if _mesh_instance and is_instance_valid(_mesh_instance):
		return

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "HourglassMesh"
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


func _build_collision() -> void:
	if get_node_or_null("CollisionShape3D"):
		return

	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.055
	capsule.height = 0.16

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = capsule
	add_child(collision)


func _ensure_return_timer() -> void:
	_return_timer = get_node_or_null("ReturnTimer") as Timer
	if _return_timer:
		if not _return_timer.timeout.is_connected(_on_return_timer_timeout):
			_return_timer.timeout.connect(_on_return_timer_timeout)
		return

	_return_timer = Timer.new()
	_return_timer.name = "ReturnTimer"
	_return_timer.one_shot = true
	_return_timer.timeout.connect(_on_return_timer_timeout)
	add_child(_return_timer)


func _on_picked_up(_pickable) -> void:
	cancel_pending_return()


func _on_return_timer_timeout() -> void:
	if is_picked_up():
		return
	if not _pending_return_anchor:
		return

	var anchor := _pending_return_anchor
	_pending_return_anchor = null
	reset_to_anchor(anchor)
	freeze = true
