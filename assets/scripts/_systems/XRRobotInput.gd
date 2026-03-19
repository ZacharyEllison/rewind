## XRRobotInput
## Sits as a child of XROrigin3D so XRHelpers can find controllers via ancestor walk.
## Exposes controller state for RobotCharacterController to consume.

class_name XRRobotInput
extends Node

@export var jump_button_action: String = "ax_button"
@export var rewind_button_action: String = "by_button"
@export var input_deadzone: float = 0.2

var _left: XRController3D
var _right: XRController3D
var _xr_camera: XRCamera3D


func _ready() -> void:
	_left = XRHelpers.get_left_controller(self)
	_right = XRHelpers.get_right_controller(self)
	_xr_camera = XRHelpers.get_xr_camera(self)
	print("XRRobotInput ready — left=%s  right=%s  cam=%s" % [str(_left), str(_right), str(_xr_camera)])


func any_active() -> bool:
	return (_left != null and _left.get_is_active()) \
		or (_right != null and _right.get_is_active())


func get_stick() -> Vector2:
	var left_vec := Vector2.ZERO
	var right_vec := Vector2.ZERO
	if _left and _left.get_is_active():
		left_vec = _left.get_vector2("primary")
		if left_vec.length() < input_deadzone:
			left_vec = Vector2.ZERO
	if _right and _right.get_is_active():
		right_vec = _right.get_vector2("primary")
		if right_vec.length() < input_deadzone:
			right_vec = Vector2.ZERO
	if left_vec.length_squared() >= right_vec.length_squared():
		return left_vec
	return right_vec


func is_jump_pressed() -> bool:
	if _left and _left.get_is_active() and _left.is_button_pressed(jump_button_action):
		return true
	if _right and _right.get_is_active() and _right.is_button_pressed(jump_button_action):
		return true
	return false


func is_rewind_pressed() -> bool:
	if _left and _left.get_is_active() and _left.is_button_pressed(rewind_button_action):
		return true
	if _right and _right.get_is_active() and _right.is_button_pressed(rewind_button_action):
		return true
	return false


func get_xr_camera() -> XRCamera3D:
	return _xr_camera
