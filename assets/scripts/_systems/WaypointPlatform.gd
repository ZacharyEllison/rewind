## WaypointPlatform
## An AnimatableBody3D that slides through a series of exported world-space waypoints.
## Call move_to_waypoint(index) to move to any stop, including reversing from the
## platform's current in-between position.
## reset() snaps instantly back to waypoints[0] and is called automatically on new_attempt_started.

class_name WaypointPlatform
extends AnimatableBody3D

## World-space positions for each stop. Index 0 is the starting position.
@export var waypoints: PackedVector3Array = []
## Seconds to travel between any two consecutive waypoints.
@export var move_duration: float = 2.5

var _current_waypoint: int = 0
var _is_moving: bool = false
var _move_from: Vector3
var _move_to: Vector3
var _move_elapsed: float = 0.0
var _move_duration_actual: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	if waypoints.size() > 0:
		global_position = waypoints[0]
	_build_mesh()
	_build_collision()
	_connect_game_manager()


func _build_mesh() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(7.0, 0.4, 5.0)
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
	box.size = Vector3(7.0, 0.4, 5.0)
	var col := CollisionShape3D.new()
	col.shape = box
	add_child(col)


func _connect_game_manager() -> void:
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_signal("new_attempt_started"):
		gm.new_attempt_started.connect(reset)


## Move the platform to the given waypoint index.
## Ignored if the index is out of range or already the current move target.
func move_to_waypoint(index: int) -> void:
	if index < 0 or index >= waypoints.size():
		return
	if _is_moving and _current_waypoint == index:
		return
	if not _is_moving and _current_waypoint == index and global_position.is_equal_approx(waypoints[index]):
		return
	_current_waypoint = index
	_start_move(global_position, waypoints[index])
	print("WaypointPlatform: moving to waypoint %d" % index)


func _start_move(from: Vector3, to: Vector3) -> void:
	_move_from = from
	_move_to = to
	_move_elapsed = 0.0
	_move_duration_actual = move_duration
	_is_moving = true


func _physics_process(delta: float) -> void:
	if not _is_moving:
		return
	_move_elapsed += delta
	var t: float = clampf(_move_elapsed / _move_duration_actual, 0.0, 1.0)
	var eased: float = t * t * (3.0 - 2.0 * t)
	global_position = _move_from.lerp(_move_to, eased)
	if t >= 1.0:
		global_position = _move_to
		_is_moving = false


## Snap instantly back to the starting waypoint. Called by GameManager.new_attempt_started.
func reset() -> void:
	_is_moving = false
	_move_elapsed = 0.0
	_current_waypoint = 0
	if waypoints.size() > 0:
		global_position = waypoints[0]
	print("WaypointPlatform: reset")
