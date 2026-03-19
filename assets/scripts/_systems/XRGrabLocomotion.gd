## XRGrabLocomotion.gd
## Provides held-stick camera rotation plus world-drag locomotion for VR.
## Hold a thumbstick click (primary_click) and move the stick left/right to
## rotate the player view. While held, moving the controller in physical space
## drags the XROrigin through the world.

extends Node

@export var left_controller: XRController3D
@export var right_controller: XRController3D
@export var xr_origin: XROrigin3D
@export var drag_scale: float = 2.0
@export var rotation_speed_degrees: float = 120.0
@export var input_deadzone: float = 0.2

var _left_dragging: bool = false
var _right_dragging: bool = false
var _left_anchor_local: Vector3 = Vector3.ZERO
var _right_anchor_local: Vector3 = Vector3.ZERO
var _robot: Node3D


func _ready() -> void:
	if not left_controller:
		left_controller = XRHelpers.get_left_controller(self)
	if not right_controller:
		right_controller = XRHelpers.get_right_controller(self)
	_robot = _find_robot()


func _physics_process(delta: float) -> void:
	var origin := xr_origin if xr_origin else get_parent() as XROrigin3D
	if not origin:
		return
	if not _robot or not is_instance_valid(_robot):
		_robot = _find_robot()

	_rotate_origin(origin, delta)
	_process_drag(origin, left_controller, true)
	_process_drag(origin, right_controller, false)


func _get_locomotion_stick() -> Vector2:
	var left_vec := _get_pressed_stick(left_controller)
	var right_vec := _get_pressed_stick(right_controller)
	if left_vec.length_squared() >= right_vec.length_squared():
		return left_vec
	return right_vec


func _get_pressed_stick(controller: XRController3D) -> Vector2:
	if not controller or not controller.get_is_active():
		return Vector2.ZERO
	if not controller.is_button_pressed("primary_click"):
		return Vector2.ZERO

	var stick := controller.get_vector2("primary")
	if stick.length() < input_deadzone:
		return Vector2.ZERO
	return stick


func _rotate_origin(origin: XROrigin3D, delta: float) -> void:
	if not _robot:
		return

	var stick := _get_locomotion_stick()
	if stick == Vector2.ZERO:
		return

	var yaw_input := stick.x
	if absf(yaw_input) < input_deadzone:
		return

	var yaw_radians := -deg_to_rad(rotation_speed_degrees) * yaw_input * delta
	var robot_position := _robot.global_position
	var offset := origin.global_position - robot_position
	var horizontal_offset := Vector3(offset.x, 0.0, offset.z)
	if horizontal_offset.length_squared() <= 0.000001:
		return

	horizontal_offset = horizontal_offset.rotated(Vector3.UP, yaw_radians)
	origin.global_position = Vector3(
		robot_position.x + horizontal_offset.x,
		origin.global_position.y,
		robot_position.z + horizontal_offset.z
	)
	origin.rotate_y(yaw_radians)


func _process_drag(origin: XROrigin3D, controller: XRController3D, is_left: bool) -> void:
	if not controller or not controller.get_is_active():
		_set_drag_state(is_left, false, Vector3.ZERO)
		return

	var pressed := controller.is_button_pressed("primary_click")
	if pressed and not _is_dragging(is_left):
		_set_drag_state(is_left, true, controller.transform.origin)
	elif not pressed:
		_set_drag_state(is_left, false, Vector3.ZERO)
		return

	if not _is_dragging(is_left):
		return

	var current_local := controller.transform.origin
	var delta_local := current_local - _get_anchor_local(is_left)
	if delta_local.length_squared() <= 0.000001:
		return

	var delta_world := origin.global_transform.basis * delta_local
	delta_world.y = 0.0
	origin.global_position -= delta_world * drag_scale
	_set_anchor_local(is_left, current_local)


func _is_dragging(is_left: bool) -> bool:
	return _left_dragging if is_left else _right_dragging


func _get_anchor_local(is_left: bool) -> Vector3:
	return _left_anchor_local if is_left else _right_anchor_local


func _set_anchor_local(is_left: bool, anchor: Vector3) -> void:
	if is_left:
		_left_anchor_local = anchor
	else:
		_right_anchor_local = anchor


func _set_drag_state(is_left: bool, dragging: bool, anchor: Vector3) -> void:
	if is_left:
		_left_dragging = dragging
		_left_anchor_local = anchor
	else:
		_right_dragging = dragging
		_right_anchor_local = anchor


func _find_robot() -> Node3D:
	var root := get_parent().get_parent() if get_parent() else null
	if root:
		var robot := root.get_node_or_null("RobotCharacter") as Node3D
		if robot:
			return robot
		return root.find_child("RobotCharacter", true, false) as Node3D
	return null
