## PressureButton
## A pressure-activated Area3D.
## Detects both CharacterBody3D (player) and Area3D nodes in the "ghost_body" group (ghosts).
## Non-latching by default: deactivates when all activators leave.
## reset() forces inactive without emitting signals, called automatically on new_attempt_started.

class_name PressureButton
extends Area3D

signal activated
signal deactivated

## If true, stays active permanently once triggered. If false, deactivates when all activators leave.
@export var latching: bool = false

var _is_active: bool = false
## Counts all activators currently overlapping (player bodies + ghost areas).
var _activators_inside: int = 0
var _mesh_instance: MeshInstance3D


func _ready() -> void:
	_build_mesh()
	_build_collision()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_connect_game_manager()


func _build_mesh() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 0.15, 1.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.15, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.05, 0.05)
	mat.emission_energy_multiplier = 1.0
	box.material = mat
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = box
	add_child(_mesh_instance)


func _build_collision() -> void:
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 0.35, 1.6)
	var col := CollisionShape3D.new()
	col.shape = box
	add_child(col)


func _connect_game_manager() -> void:
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_signal("new_attempt_started"):
		gm.new_attempt_started.connect(reset)


func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	_activators_inside += 1
	if not _is_active:
		_set_active(true)


func _on_body_exited(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	_activators_inside = maxi(_activators_inside - 1, 0)
	if not latching and _activators_inside == 0 and _is_active:
		_set_active(false)


## Ghost areas must be in the "ghost_body" group to activate this button.
func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("ghost_body"):
		return
	_activators_inside += 1
	if not _is_active:
		_set_active(true)


func _on_area_exited(area: Area3D) -> void:
	if not area.is_in_group("ghost_body"):
		return
	_activators_inside = maxi(_activators_inside - 1, 0)
	if not latching and _activators_inside == 0 and _is_active:
		_set_active(false)


## Silently force the button back to inactive (no signals emitted). Called on attempt reset.
func reset() -> void:
	_activators_inside = 0
	if _is_active:
		_is_active = false
		_update_visual(false)
	print("PressureButton: reset")


func _set_active(value: bool) -> void:
	_is_active = value
	_update_visual(value)
	if value:
		emit_signal("activated")
		print("PressureButton: activated")
	else:
		emit_signal("deactivated")
		print("PressureButton: deactivated")


func _update_visual(active: bool) -> void:
	if not _mesh_instance:
		return
	var mat := StandardMaterial3D.new()
	if active:
		mat.albedo_color = Color(0.15, 0.85, 0.15)
		mat.emission_enabled = true
		mat.emission = Color(0.05, 0.5, 0.05)
		mat.emission_energy_multiplier = 1.0
	else:
		mat.albedo_color = Color(0.85, 0.15, 0.15)
		mat.emission_enabled = true
		mat.emission = Color(0.5, 0.05, 0.05)
		mat.emission_energy_multiplier = 1.0
	_mesh_instance.mesh.material = mat
