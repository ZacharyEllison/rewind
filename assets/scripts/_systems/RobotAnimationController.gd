## RobotAnimationController
## Drives the robot's AnimationPlayer based on the parent CharacterBody3D's velocity.
## Attach this to the robot_gobot mesh node (child of CharacterBody3D).
## Gracefully handles missing animation names — won't crash if the GLB lacks specific clips.

extends Node3D

## Speed below which the idle animation plays
@export var idle_threshold: float = 0.5
## Speed above which the run animation plays instead of walk
@export var run_threshold: float = 4.0

var _anim_player: AnimationPlayer
var _body: CharacterBody3D
var _current_anim: String = ""


func _ready() -> void:
	# Find AnimationPlayer anywhere inside this node's subtree
	_anim_player = _find_animation_player(self)
	if not _anim_player:
		push_warning("RobotAnimationController: no AnimationPlayer found in %s" % name)
		return

	# Parent must be the CharacterBody3D
	_body = get_parent() as CharacterBody3D
	if not _body:
		push_warning("RobotAnimationController: parent is not a CharacterBody3D")


func _physics_process(_delta: float) -> void:
	if not _anim_player or not _body:
		return

	var horizontal_speed := Vector3(_body.velocity.x, 0.0, _body.velocity.z).length()
	var on_floor := _body.is_on_floor()

	var desired: String
	if not on_floor:
		if _body.velocity.y > 0.0:
			desired = "jump"
		else:
			desired = "fall"
	elif horizontal_speed > run_threshold:
		desired = "run"
	elif horizontal_speed > idle_threshold:
		desired = "walk"
	else:
		desired = "idle"

	_play(desired)


func _play(anim_name: String) -> void:
	if anim_name == _current_anim:
		return
	# Try exact name first, then fallbacks
	var candidates := _fallbacks(anim_name)
	for candidate in candidates:
		if _anim_player.has_animation(candidate):
			_anim_player.play(candidate)
			_current_anim = anim_name
			return
	# If nothing matched, stay on current animation


func _fallbacks(anim_name: String) -> Array[String]:
	# Map desired state to likely animation name variants in the GLB
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
