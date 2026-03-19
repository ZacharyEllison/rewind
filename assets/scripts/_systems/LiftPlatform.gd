## LiftPlatform
## An AnimatableBody3D that smoothly rises by [member lift_height] when [method activate] is called.
## Move in _physics_process so CharacterBody3D.move_and_slide() correctly carries the player.

class_name LiftPlatform
extends AnimatableBody3D

## Vertical distance (in units) the platform rises when activated.
@export var lift_height: float = 7.8
## Duration in seconds to complete the rise.
@export var lift_duration: float = 3.0

var _start_y: float
var _target_y: float
var _elapsed: float = 0.0
var _is_rising: bool = false


func _ready() -> void:
	sync_to_physics = true
	_start_y = global_position.y
	_target_y = _start_y + lift_height
	_build_mesh()
	_build_collision()


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


## Call this to start the lift rising. Ignored if already at the top or currently rising.
func activate() -> void:
	if _is_rising or global_position.y >= _target_y - 0.01:
		return
	_elapsed = 0.0
	_is_rising = true
	print("LiftPlatform: rising to y=%.2f" % _target_y)


func _physics_process(delta: float) -> void:
	if not _is_rising:
		return
	_elapsed += delta
	var t: float = clamp(_elapsed / lift_duration, 0.0, 1.0)
	# Smoothstep easing
	var eased: float = t * t * (3.0 - 2.0 * t)
	global_position.y = lerpf(_start_y, _target_y, eased)
	if t >= 1.0:
		global_position.y = _target_y
		_is_rising = false
		print("LiftPlatform: reached top")
