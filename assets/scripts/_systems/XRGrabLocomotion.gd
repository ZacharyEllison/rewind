## XRGrabLocomotion.gd
## Provides camera-drag locomotion for VR. When the player holds the thumbstick
## click (primary_click) on either controller and deflects the stick, the
## XROrigin moves opposite the stick direction relative to the headset view.

extends Node

@export var left_controller: XRController3D
@export var right_controller: XRController3D
@export var xr_origin: XROrigin3D
@export var movement_speed: float = 2.5
@export var input_deadzone: float = 0.2

var _xr_camera: XRCamera3D


func _ready() -> void:
	if not left_controller:
		left_controller = XRHelpers.get_left_controller(self)
	if not right_controller:
		right_controller = XRHelpers.get_right_controller(self)
	_xr_camera = XRHelpers.get_xr_camera(self)


func _physics_process(delta: float) -> void:
	var origin := xr_origin if xr_origin else get_parent() as XROrigin3D
	if not origin:
		return

	var stick := _get_locomotion_stick()
	if stick == Vector2.ZERO:
		return

	var move_dir := _get_drag_direction(stick)
	if move_dir == Vector3.ZERO:
		return

	origin.global_position += move_dir * movement_speed * delta


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


func _get_drag_direction(stick: Vector2) -> Vector3:
	var basis_source: Node3D = _xr_camera if _xr_camera else xr_origin
	if not basis_source:
		return Vector3(-stick.x, 0.0, stick.y).normalized() * minf(stick.length(), 1.0)

	var forward := -basis_source.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	else:
		forward = Vector3.FORWARD

	var right := basis_source.global_transform.basis.x
	right.y = 0.0
	if right.length_squared() > 0.0001:
		right = right.normalized()
	else:
		right = Vector3.RIGHT

	var move := (right * stick.x) + (forward * stick.y)
	if move.length_squared() <= 0.0001:
		return Vector3.ZERO
	return -move.normalized() * minf(stick.length(), 1.0)
