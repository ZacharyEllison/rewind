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
	dropped.connect(_on_dropped)


func is_upside_down() -> bool:
	return global_transform.basis.y.dot(Vector3.UP) <= upside_down_dot_threshold


func snap_to_anchor(anchor: Node3D) -> void:
	if not anchor:
		return
	_set_top_level_preserving_transform(false)
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


func _build_mesh() -> void:
	if _mesh_instance and is_instance_valid(_mesh_instance):
		return

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "HourglassMesh"
	_mesh_instance.mesh = load("res://assets/models/hourglass/model-triangulated.obj")
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
	_set_top_level_preserving_transform(true)
	sleeping = false


func _on_dropped(_pickable) -> void:
	if not freeze:
		_set_top_level_preserving_transform(true)
		sleeping = false


func _on_return_timer_timeout() -> void:
	if is_picked_up():
		return
	if not _pending_return_anchor:
		return

	var anchor := _pending_return_anchor
	_pending_return_anchor = null
	reset_to_anchor(anchor)
	freeze = true


func _set_top_level_preserving_transform(enabled: bool) -> void:
	if top_level == enabled:
		return

	var current_global := global_transform
	top_level = enabled
	global_transform = current_global
