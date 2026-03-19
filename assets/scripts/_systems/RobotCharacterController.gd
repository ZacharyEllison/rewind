## RobotCharacterController
## Platformer physics (gravity, accel/decel, jump) with VR joystick input.
## XR input is provided by an XRRobotInput node living under XROrigin3D.

extends CharacterBody3D

@export var xr_input: XRRobotInput

@export_group("Movement")
@export var max_speed: float = 6.0
@export var acceleration: float = 14.0
@export var deceleration: float = 14.0
@export var air_accel_factor: float = 0.5
@export var turn_speed: float = 10.0

@export_group("Jump")
@export var jump_velocity: float = 12.5

@export_group("Input")
@export var input_deadzone: float = 0.2

@export_group("Level")
@export var fall_threshold: float = -10.0
@export var spawn_position: Vector3 = Vector3(0.0, 0.5, 0.0)

@export_group("Visuals")
## Assign the robot mesh child in the Inspector to avoid a hard-coded node name lookup.
## If left empty the controller falls back to searching for a child named "robot_gobot".
@export var robot_mesh: Node3D

var _gravity: Vector3
var _facing_dir: Vector3 = Vector3.FORWARD
var _rewind_was_pressed: bool = false
var game_manager: Node


func _ready() -> void:
	var g_mag: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var g_dir: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	_gravity = g_dir * g_mag
	_resolve_xr_input()
	game_manager = get_parent().get_node_or_null("GameManager")
	spawn_position = global_position
	print("RobotController Ready - max_speed: %.1f, jump: %.1f, xr_input=%s" % [max_speed, jump_velocity, str(xr_input)])
	if game_manager:
		game_manager.start_recording()


func _physics_process(delta: float) -> void:
	if not xr_input:
		_resolve_xr_input()
	_check_fall()
	_check_rewind_trigger()
	if game_manager and game_manager.is_rewinding_active():
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
	if xr_input:
		pressed = xr_input.is_rewind_pressed()
	if Input.is_action_just_pressed("ui_cancel"):
		pressed = true

	if pressed and not _rewind_was_pressed:
		if game_manager:
			if game_manager.is_rewinding_active():
				game_manager.complete_rewind()
			elif game_manager.is_recording_active():
				game_manager.stop_recording()
				game_manager.trigger_rewind()
			else:
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
	if not game_manager:
		return
	if game_manager.is_recording_active():
		game_manager.stop_recording()
		game_manager.trigger_rewind()
	elif not game_manager.is_rewinding_active():
		game_manager.start_recording()


# --- Input ---

func _get_combined_stick() -> Vector2:
	var controller_vec := Vector2.ZERO
	if xr_input:
		controller_vec = xr_input.get_stick()

	# Desktop keyboard fallback
	var kb_x := (float(Input.is_key_pressed(KEY_D)) + float(Input.is_key_pressed(KEY_RIGHT))) \
			  - (float(Input.is_key_pressed(KEY_A)) + float(Input.is_key_pressed(KEY_LEFT)))
	var kb_y := (float(Input.is_key_pressed(KEY_W)) + float(Input.is_key_pressed(KEY_UP))) \
			  - (float(Input.is_key_pressed(KEY_S)) + float(Input.is_key_pressed(KEY_DOWN)))
	var kb_vec := Vector2(clamp(kb_x, -1.0, 1.0), clamp(kb_y, -1.0, 1.0))

	if kb_vec.length_squared() > controller_vec.length_squared():
		return kb_vec
	return controller_vec


# --- Movement ---

func _apply_horizontal_movement(delta: float) -> void:
	var stick := _get_combined_stick()
	var move_dir := Vector3.ZERO

	if stick.length_squared() > 0.0:
		var xr_cam: XRCamera3D = xr_input.get_xr_camera() if xr_input else null
		var any_active := xr_input != null and xr_input.any_active()
		if xr_cam and any_active:
			move_dir = xr_cam.global_transform.basis * Vector3(stick.x, 0.0, -stick.y)
		else:
			var cam3d := get_viewport().get_camera_3d()
			if cam3d:
				move_dir = cam3d.global_transform.basis * Vector3(stick.x, 0.0, -stick.y)
			else:
				move_dir = Vector3(stick.x, 0.0, -stick.y)
		move_dir.y = 0.0
		if move_dir.length_squared() > 0.0001:
			move_dir = move_dir.normalized()
		else:
			move_dir = Vector3.ZERO

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var current_speed := horizontal.length()
	var accel_factor := 1.0 if is_on_floor() else air_accel_factor

	if move_dir != Vector3.ZERO:
		var target_speed := max_speed * accel_factor if not is_on_floor() else max_speed
		velocity.x = move_dir.x * target_speed
		velocity.z = move_dir.z * target_speed
		_facing_dir = move_dir
	else:
		var new_speed := maxf(current_speed - deceleration * accel_factor * delta, 0.0)
		if current_speed > 0.0:
			var horizontal_dir := horizontal / current_speed
			velocity.x = horizontal_dir.x * new_speed
			velocity.z = horizontal_dir.z * new_speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0


func _apply_jump() -> void:
	var jump_pressed := false
	if xr_input:
		jump_pressed = xr_input.is_jump_pressed()
	if Input.is_action_just_pressed("ui_accept"):
		jump_pressed = true
	if jump_pressed and is_on_floor():
		velocity.y = jump_velocity


## Smoothly rotate the mesh child to face the movement direction.
func _update_facing(delta: float) -> void:
	if _facing_dir == Vector3.ZERO:
		return
	var mesh: Node3D = robot_mesh if robot_mesh else get_node_or_null("robot_gobot") as Node3D
	if not mesh:
		return
	var target_basis := Basis.looking_at(-_facing_dir, Vector3.UP)
	mesh.global_transform.basis = mesh.global_transform.basis.slerp(target_basis, turn_speed * delta)


func _resolve_xr_input() -> void:
	if xr_input and is_instance_valid(xr_input):
		return

	var scene_root := get_parent()
	if scene_root:
		xr_input = scene_root.get_node_or_null("XROrigin3D/XRRobotInput") as XRRobotInput

	if not xr_input and scene_root:
		xr_input = scene_root.find_child("XRRobotInput", true, false) as XRRobotInput
