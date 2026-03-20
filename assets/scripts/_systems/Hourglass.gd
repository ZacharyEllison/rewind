## Hourglass
## XRTools-pickable hourglass used by the player-following pedestal rewind rig.
## collision_layer must include layer 3 (pickable) so FunctionPickup can detect it.
## When released, physics (gravity) applies so it can fall to the pedestal.
## lerp_to_anchor() smoothly animates it to a target anchor over ~0.35 s.

class_name Hourglass
extends XRToolsPickable

@export var upside_down_dot_threshold: float = -0.7
@export var return_delay: float = 3.0

var _mesh_instance: MeshInstance3D = null
var _return_timer: Timer = null
var _pending_return_anchor: Node3D = null

## Spatial anchors at the two flat wooden cap faces of the hourglass model.
## top_cap is the cap facing UP when upright; bottom_cap faces DOWN.
## Populated from the TopCap / BottomCap child nodes in the scene.
var top_cap: Node3D = null
var bottom_cap: Node3D = null

## Lerp-to-anchor state
var _lerp_active: bool = false
var _lerp_start: Transform3D
var _lerp_target_anchor: Node3D = null
var _lerp_elapsed: float = 0.0
var _lerp_duration: float = 0.35


func _ready() -> void:
	super()
	add_to_group("hourglass_pickable")
	_build_mesh()
	_build_collision()
	_ensure_return_timer()
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)
	top_cap = get_node_or_null("TopCap") as Node3D
	bottom_cap = get_node_or_null("BottomCap") as Node3D


func is_upside_down() -> bool:
	return global_transform.basis.y.dot(Vector3.UP) <= upside_down_dot_threshold


## Instantly teleport to anchor. Used only for reset / new-attempt snaps.
func snap_to_anchor(anchor: Node3D) -> void:
	if not anchor:
		return
	_lerp_active = false
	_lerp_target_anchor = null
	_set_top_level_preserving_transform(false)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true
	freeze = true
	global_transform = anchor.global_transform


## Smoothly lerp to anchor over `duration` seconds.
## Immediately freezes physics and moves the hourglass via _process interpolation.
## The anchor's live transform is tracked, so moving pedestals work correctly.
func lerp_to_anchor(anchor: Node3D, duration: float = 0.35) -> void:
	if not anchor:
		return
	cancel_pending_return()
	_set_top_level_preserving_transform(true)
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true
	_lerp_start = global_transform
	_lerp_target_anchor = anchor
	_lerp_elapsed = 0.0
	_lerp_duration = maxf(duration, 0.05)
	_lerp_active = true


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


func _process(delta: float) -> void:
	if not _lerp_active:
		return
	if not _lerp_target_anchor or not is_instance_valid(_lerp_target_anchor):
		_lerp_active = false
		_lerp_target_anchor = null
		return
	_lerp_elapsed += delta
	var t: float = clampf(_lerp_elapsed / _lerp_duration, 0.0, 1.0)
	var eased: float = t * t * (3.0 - 2.0 * t)
	global_transform = _lerp_start.interpolate_with(_lerp_target_anchor.global_transform, eased)
	if t >= 1.0:
		global_transform = _lerp_target_anchor.global_transform
		_lerp_active = false
		_lerp_target_anchor = null
		_set_top_level_preserving_transform(false)
		freeze = true


func _build_mesh() -> void:
	if _mesh_instance and is_instance_valid(_mesh_instance):
		return
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "HourglassMesh"
	_mesh_instance.mesh = load("res://assets/models/hourglass/model-triangulated.obj")
	_mesh_instance.scale = Vector3(0.1, 0.1, 0.1)
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
	_lerp_active = false
	_lerp_target_anchor = null
	_set_top_level_preserving_transform(true)
	sleeping = false


func _on_dropped(_pickable) -> void:
	# Always enable physics when dropped so gravity pulls it down.
	# The old code gated on `if not freeze` which prevented falling because
	# release_mode = ORIGINAL restores the initial freeze = true state.
	_lerp_active = false
	_lerp_target_anchor = null
	_set_top_level_preserving_transform(true)
	freeze = false
	sleeping = false


func _on_return_timer_timeout() -> void:
	if is_picked_up():
		return
	if not _pending_return_anchor:
		return
	var anchor := _pending_return_anchor
	_pending_return_anchor = null
	lerp_to_anchor(anchor)


func _set_top_level_preserving_transform(enabled: bool) -> void:
	if top_level == enabled:
		return
	var current_global := global_transform
	top_level = enabled
	global_transform = current_global
