## XRGrabLocomotion.gd
## Provides world-grab locomotion for VR. When the player holds the thumbstick
## click (primary_click) on either controller, the world moves inversely to
## the hand's motion — creating the sensation of physically pulling yourself
## through the environment.

extends Node

@export var left_controller: XRController3D
@export var right_controller: XRController3D
@export var xr_origin: XROrigin3D
@export var movement_scale: float = 1.0

var _left_grabbing: bool = false
var _right_grabbing: bool = false
var _left_anchor: Vector3 = Vector3.ZERO
var _right_anchor: Vector3 = Vector3.ZERO
var _left_was_pressed: bool = false
var _right_was_pressed: bool = false


func _physics_process(_delta: float) -> void:
	var origin := xr_origin if xr_origin else get_parent() as XROrigin3D
	if not origin:
		return
	_process_left(origin)
	_process_right(origin)


func _process_left(origin: XROrigin3D) -> void:
	if not left_controller or not left_controller.get_is_active():
		_left_grabbing = false
		_left_was_pressed = false
		return
	var pressed := left_controller.is_button_pressed("primary_click")
	if pressed and not _left_was_pressed:
		_left_anchor = left_controller.global_position
		_left_grabbing = true
	elif not pressed:
		_left_grabbing = false
	if _left_grabbing and pressed:
		var current := left_controller.global_position
		var delta := current - _left_anchor
		origin.global_position -= delta * movement_scale
		_left_anchor = left_controller.global_position
	_left_was_pressed = pressed


func _process_right(origin: XROrigin3D) -> void:
	if not right_controller or not right_controller.get_is_active():
		_right_grabbing = false
		_right_was_pressed = false
		return
	var pressed := right_controller.is_button_pressed("primary_click")
	if pressed and not _right_was_pressed:
		_right_anchor = right_controller.global_position
		_right_grabbing = true
	elif not pressed:
		_right_grabbing = false
	if _right_grabbing and pressed:
		var current := right_controller.global_position
		var delta := current - _right_anchor
		origin.global_position -= delta * movement_scale
		_right_anchor = right_controller.global_position
	_right_was_pressed = pressed
