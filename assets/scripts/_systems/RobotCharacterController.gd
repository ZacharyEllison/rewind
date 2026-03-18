## RobotCharacterController
## Platformer physics (gravity, accel/decel, jump) with VR joystick input from either controller.
## Movement direction is relative to XRCamera3D — no follow camera needed.

extends CharacterBody3D

@export var left_controller: XRController3D
@export var right_controller: XRController3D
@export var xr_camera: XRCamera3D

@export_group("Movement")
@export var max_speed: float = 6.0
@export var acceleration: float = 14.0
@export var deceleration: float = 14.0
@export var air_accel_factor: float = 0.5
@export var turn_speed: float = 10.0

@export_group("Jump")
@export var jump_velocity: float = 12.5
@export var jump_button_action: String = "ax_button"

@export_group("Rewind")
@export var rewind_button_action: String = "by_button"

@export_group("Input")
@export var input_deadzone: float = 0.2

@export_group("Level")
@export var fall_threshold: float = -10.0
@export var spawn_position: Vector3 = Vector3(0.0, 0.5, 0.0)

var _gravity: Vector3
var _facing_dir: Vector3 = Vector3.FORWARD
var _rewind_was_pressed: bool = false
var game_manager: Node


func _ready() -> void:
	var g_mag: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var g_dir: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	_gravity = g_dir * g_mag
	game_manager = get_parent().get_node_or_null("GameManager")
	spawn_position = global_position
	print("RobotController Ready - max_speed: %.1f, jump: %.1f" % [max_speed, jump_velocity])
	# Auto-start recording immediately so the first run is captured
	if game_manager:
		game_manager.start_recording()


func _physics_process(delta: float) -> void:
	_check_fall()
	_check_rewind_trigger()
	# Block movement during rewind playback
	if game_manager and game_manager.is_rewinding:
		move_and_slide()
		return
	if not is_on_floor():
		velocity += _gravity * delta
	_apply_horizontal_movement(delta)
	_apply_jump()
	move_and_slide()
	_update_facing(delta)


# --- Rewind trigger ---

func _check_rewind_trigger() -> void:
	var pressed := false
	if left_controller and left_controller.get_is_active():
		pressed = pressed or left_controller.is_button_pressed(rewind_button_action)
	if right_controller and right_controller.get_is_active():
		pressed = pressed or right_controller.is_button_pressed(rewind_button_action)
	if Input.is_action_just_pressed("ui_cancel"):  # Escape - desktop fallback
		pressed = true

	# Edge-detect: only fire on the frame the button first goes down
	if pressed and not _rewind_was_pressed:
		if game_manager:
			if game_manager.is_recording:
				game_manager.stop_recording()
				# Playback is driven by main.gd via the rewinding_started signal
				game_manager.trigger_rewind()
			elif not game_manager.is_rewinding:
				# Start a fresh attempt after rewind has finished
				game_manager.start_new_attempt()
				game_manager.start_recording()
	_rewind_was_pressed = pressed


# --- Fall / respawn ---

func _check_fall() -> void:
	if global_position.y < fall_threshold:
		respawn()


func respawn() -> void:
	velocity = Vector3.ZERO
	global_position = spawn_position
	if game_manager:
		game_manager.retry_current_attempt()


# --- Input ---

# Returns the thumbstick vector from whichever controller has greater magnitude.
# Using the larger magnitude (not sum) prevents accidental speed doubling when a
# resting hand drifts slightly on the stick.
func _get_combined_stick() -> Vector2:
	var left_vec := Vector2.ZERO
	var right_vec := Vector2.ZERO

	if left_controller and left_controller.get_is_active():
		left_vec = left_controller.get_vector2("primary")
		if left_vec.length() < input_deadzone:
			left_vec = Vector2.ZERO

	if right_controller and right_controller.get_is_active():
		right_vec = right_controller.get_vector2("primary")
		if right_vec.length() < input_deadzone:
			right_vec = Vector2.ZERO

	if left_vec.length_squared() >= right_vec.length_squared():
		return left_vec
	return right_vec


# --- Movement ---

func _apply_horizontal_movement(delta: float) -> void:
	var stick := _get_combined_stick()
	var move_dir := Vector3.ZERO

	if xr_camera and stick.length_squared() > 0.0:
		var cam_basis := xr_camera.global_transform.basis
		# stick.x = strafe right, stick.y = forward (positive y on stick = forward = -Z)
		move_dir = cam_basis * Vector3(stick.x, 0.0, -stick.y)
		move_dir.y = 0.0
		move_dir = move_dir.normalized()

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var current_speed := horizontal.length()
	var accel_factor := 1.0 if is_on_floor() else air_accel_factor

	if move_dir != Vector3.ZERO:
		var target_speed := minf(current_speed + acceleration * accel_factor * delta, max_speed)
		velocity.x = move_dir.x * target_speed
		velocity.z = move_dir.z * target_speed
		_facing_dir = move_dir
	else:
		var new_speed := maxf(current_speed - deceleration * accel_factor * delta, 0.0)
		if current_speed > 0.0:
			velocity.x = (horizontal / current_speed).x * new_speed
			velocity.z = (horizontal / current_speed).z * new_speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0


func _apply_jump() -> void:
	var jump_pressed := false

	if left_controller and left_controller.get_is_active():
		jump_pressed = jump_pressed or left_controller.is_button_pressed(jump_button_action)
	if right_controller and right_controller.get_is_active():
		jump_pressed = jump_pressed or right_controller.is_button_pressed(jump_button_action)

	# Desktop fallback — ui_accept (Space) needs no InputMap entry
	if Input.is_action_just_pressed("ui_accept"):
		jump_pressed = true

	if jump_pressed and is_on_floor():
		velocity.y = jump_velocity


# Smoothly rotate the mesh child to face the movement direction.
# Rotates the visual child only — CharacterBody3D capsule stays axis-aligned.
func _update_facing(delta: float) -> void:
	if _facing_dir == Vector3.ZERO:
		return
	var mesh := get_node_or_null("robot_gobot")
	if not mesh:
		return
	var target_basis := Basis.looking_at(_facing_dir, Vector3.UP)
	mesh.global_transform.basis = mesh.global_transform.basis.slerp(target_basis, turn_speed * delta)
