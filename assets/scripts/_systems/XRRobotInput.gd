## XRRobotInput
## Sits as a child of XROrigin3D so XRHelpers can find controllers via ancestor walk.
## Exposes controller state for RobotCharacterController to consume.

class_name XRRobotInput
extends Node

@export var jump_button_action: String = "trigger_click"
@export var rewind_button_action: String = "by_button"
@export var input_deadzone: float = 0.2
@export var stick_release_suppression_ms: int = 150

var _left: XRController3D
var _right: XRController3D
var _xr_camera: XRCamera3D
var _left_was_clicking: bool = false
var _right_was_clicking: bool = false
var _left_suppressed_until_ms: int = 0
var _right_suppressed_until_ms: int = 0


func _ready() -> void:
	_left = XRHelpers.get_left_controller(self)
	_right = XRHelpers.get_right_controller(self)
	_xr_camera = XRHelpers.get_xr_camera(self)
	print("XRRobotInput ready — left=%s  right=%s  cam=%s" % [str(_left), str(_right), str(_xr_camera)])


func any_active() -> bool:
	return (_left != null and _left.get_is_active()) \
		or (_right != null and _right.get_is_active())


func get_stick() -> Vector2:
	_update_click_state()

	var left_vec := Vector2.ZERO
	var right_vec := Vector2.ZERO
	if _left and _left.get_is_active():
		if not _is_stick_suppressed(_left, true):
			left_vec = _left.get_vector2("primary")
			if left_vec.length() < input_deadzone:
				left_vec = Vector2.ZERO
	if _right and _right.get_is_active():
		if not _is_stick_suppressed(_right, false):
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


func _update_click_state() -> void:
	_update_controller_click_state(_left, true)
	_update_controller_click_state(_right, false)


func _update_controller_click_state(controller: XRController3D, is_left: bool) -> void:
	var is_clicking := controller != null and controller.get_is_active() and controller.is_button_pressed("primary_click")
	var was_clicking := _left_was_clicking if is_left else _right_was_clicking

	if was_clicking and not is_clicking:
		var suppressed_until := Time.get_ticks_msec() + stick_release_suppression_ms
		if is_left:
			_left_suppressed_until_ms = suppressed_until
		else:
			_right_suppressed_until_ms = suppressed_until

	if is_left:
		_left_was_clicking = is_clicking
	else:
		_right_was_clicking = is_clicking


func _is_stick_suppressed(controller: XRController3D, is_left: bool) -> bool:
	if not controller or not controller.get_is_active():
		return true
	if controller.is_button_pressed("primary_click"):
		return true

	var suppressed_until := _left_suppressed_until_ms if is_left else _right_suppressed_until_ms
	return Time.get_ticks_msec() < suppressed_until
