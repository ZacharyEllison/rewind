## LiftPlatform
## An AnimatableBody3D that smoothly rises and falls.
## activate() raises it to the top; deactivate() lowers it back down from wherever it is.
## reset() snaps instantly to the start position (called automatically on new_attempt_started).

class_name LiftPlatform
extends AnimatableBody3D

## Vertical distance (in units) the platform travels from start to top.
@export var lift_height: float = 7.8
## Seconds for a full start-to-top or top-to-start travel.
@export var lift_duration: float = 3.0

var _start_y: float
var _top_y: float

# General movement state — handles both rising and lowering from any position.
var _is_moving: bool = false
var _move_from_y: float = 0.0
var _move_to_y: float = 0.0
var _move_elapsed: float = 0.0
var _move_duration: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	_start_y = global_position.y
	_top_y = _start_y + lift_height
	_build_mesh()
	_build_collision()
	_connect_game_manager()


func _build_mesh() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(2.8, 0.4, 2.8)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.65, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.25, 0.5)
	mat.emission_energy_multiplier = 0.6
	box.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = box
	add_child(mi)


func _build_collision() -> void:
	var box := BoxShape3D.new()
	box.size = Vector3(2.8, 0.4, 2.8)
	var col := CollisionShape3D.new()
	col.shape = box
	add_child(col)


func _connect_game_manager() -> void:
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_signal("new_attempt_started"):
		gm.new_attempt_started.connect(reset)


## Smoothly rise to the top. Ignored if already at/moving toward the top.
func activate() -> void:
	if _is_moving and _move_to_y >= _top_y - 0.01:
		return
	if global_position.y >= _top_y - 0.01:
		return
	_start_move(global_position.y, _top_y)
	print("LiftPlatform: rising to y=%.2f" % _top_y)


## Smoothly lower back to start. Ignored if already at/moving toward the bottom.
func deactivate() -> void:
	if _is_moving and _move_to_y <= _start_y + 0.01:
		return
	if global_position.y <= _start_y + 0.01:
		return
	_start_move(global_position.y, _start_y)
	print("LiftPlatform: lowering to y=%.2f" % _start_y)


## Instantly snap to the start position. Called by GameManager.new_attempt_started.
func reset() -> void:
	_is_moving = false
	_move_elapsed = 0.0
	global_position.y = _start_y
	print("LiftPlatform: reset")


func _start_move(from_y: float, to_y: float) -> void:
	_move_from_y = from_y
	_move_to_y = to_y
	_move_elapsed = 0.0
	# Scale duration proportionally so a partial move takes proportionally less time.
	var fraction: float = abs(to_y - from_y) / lift_height
	_move_duration = maxf(lift_duration * fraction, 0.05)
	_is_moving = true


func _physics_process(delta: float) -> void:
	if not _is_moving:
		return
	_move_elapsed += delta
	var t: float = clamp(_move_elapsed / _move_duration, 0.0, 1.0)
	var eased: float = t * t * (3.0 - 2.0 * t)
	global_position.y = lerpf(_move_from_y, _move_to_y, eased)
	if t >= 1.0:
		global_position.y = _move_to_y
		_is_moving = false
