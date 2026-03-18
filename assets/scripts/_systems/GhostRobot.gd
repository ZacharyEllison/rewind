## GhostRobot
## Plays back recorded positions from GameManager to show the player's past path.
## Attach to a Node3D that has the same robot mesh as a semi-transparent child.

extends Node3D

signal playback_finished

@export var playback_speed: float = 1.0

var _positions: Array[Vector3] = []
var _animations: Array[String] = []
var _index: int = 0
var _active: bool = false
## Seconds between recorded samples — must match GameManager.RECORD_INTERVAL.
const SAMPLE_INTERVAL: float = 0.1
var _elapsed: float = 0.0

var _anim_player: AnimationPlayer
var _current_anim: String = ""
var _last_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	visible = false
	_anim_player = _find_animation_player(self)
	GhostAppearance.apply(self)


func start_playback(positions: Array[Vector3], animations: Array[String] = []) -> void:
	if positions.is_empty():
		return
	_positions = positions
	_animations = animations
	_index = 0
	_elapsed = 0.0
	_active = true
	_current_anim = ""
	visible = true
	global_position = _positions[0]
	_last_position = _positions[0]


func stop_playback() -> void:
	_active = false
	visible = false
	_positions.clear()
	_animations.clear()


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
	var new_position := pos_a.lerp(pos_b, t)

	# Rotate ghost to face direction of movement
	var movement := new_position - _last_position
	var horizontal_movement := Vector3(movement.x, 0.0, movement.z)
	if horizontal_movement.length_squared() > 0.0001:
		var target_basis := Basis.looking_at(horizontal_movement.normalized(), Vector3.UP)
		global_basis = global_basis.slerp(target_basis, 0.25)

	global_position = new_position
	_last_position = new_position

	# Play the recorded animation for this frame index
	if not _animations.is_empty() and target_index < _animations.size():
		_play_anim(_animations[target_index])


func _play_anim(anim_name: String) -> void:
	if anim_name == _current_anim:
		return
	if not _anim_player:
		return
	var candidates := _fallbacks(anim_name)
	for candidate in candidates:
		if _anim_player.has_animation(candidate):
			_anim_player.play(candidate)
			_current_anim = anim_name
			return


func _fallbacks(anim_name: String) -> Array[String]:
	var map: Dictionary = {
		"idle": ["idle", "Idle", "IDLE", "rest", "Rest"],
		"walk": ["walk", "Walk", "WALK", "walking", "Walking"],
		"run":  ["run", "Run", "RUN", "running", "Running", "walk", "Walk"],
		"jump": ["jump", "Jump", "JUMP", "jump_up", "JumpUp"],
		"fall": ["fall", "Fall", "FALL", "jump_fall", "falling", "Falling", "jump", "Jump"],
	}
	var result: Array[String] = []
	if map.has(anim_name):
		result.assign(map[anim_name])
	else:
		result.append(anim_name)
	return result


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null
