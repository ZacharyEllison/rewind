## GhostRobot
## Plays back recorded positions from GameManager to show the player's past path.
## Attach to a Node3D that has the same robot mesh as a semi-transparent child.

extends Node3D

signal playback_finished

@export var playback_speed: float = 1.0

var _positions: Array[Vector3] = []
var _index: int = 0
var _active: bool = false
# Seconds between recorded samples (matches GameManager recording interval)
const SAMPLE_INTERVAL: float = 0.1
var _elapsed: float = 0.0


func _ready() -> void:
	visible = false


func start_playback(positions: Array[Vector3]) -> void:
	if positions.is_empty():
		return
	_positions = positions
	_index = 0
	_elapsed = 0.0
	_active = true
	visible = true
	global_position = _positions[0]


func stop_playback() -> void:
	_active = false
	visible = false
	_positions.clear()


func _physics_process(delta: float) -> void:
	if not _active or _positions.is_empty():
		return

	_elapsed += delta * playback_speed

	# Advance through frames based on elapsed time
	var target_index := int(_elapsed / SAMPLE_INTERVAL)

	if target_index >= _positions.size():
		stop_playback()
		emit_signal("playback_finished")
		return

	# Interpolate smoothly between the current and next sample
	var t := fmod(_elapsed, SAMPLE_INTERVAL) / SAMPLE_INTERVAL
	var pos_a: Vector3 = _positions[target_index]
	var pos_b: Vector3 = _positions[mini(target_index + 1, _positions.size() - 1)]
	global_position = pos_a.lerp(pos_b, t)
