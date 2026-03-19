## PressureButton
## A pressure-activated Area3D that emits [signal activated] when a CharacterBody3D steps on it.
## With latching = true (default), stays active permanently once triggered.

class_name PressureButton
extends Area3D

signal activated
signal deactivated

## If true, stays active once triggered (one-way latch). If false, deactivates when body leaves.
@export var latching: bool = true

var _is_active: bool = false
var _bodies_inside: int = 0
var _mesh_instance: MeshInstance3D

func _ready() -> void:
	_build_mesh()
	_build_collision()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


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


func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	_bodies_inside += 1
	if not _is_active:
		_set_active(true)


func _on_body_exited(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	_bodies_inside = maxi(_bodies_inside - 1, 0)
	if not latching and _bodies_inside == 0 and _is_active:
		_set_active(false)


func _set_active(value: bool) -> void:
	_is_active = value
	var mat := StandardMaterial3D.new()
	if value:
		mat.albedo_color = Color(0.15, 0.85, 0.15)
		mat.emission_enabled = true
		mat.emission = Color(0.05, 0.5, 0.05)
		mat.emission_energy_multiplier = 1.0
		emit_signal("activated")
		print("PressureButton: activated")
	else:
		mat.albedo_color = Color(0.85, 0.15, 0.15)
		mat.emission_enabled = true
		mat.emission = Color(0.5, 0.05, 0.05)
		mat.emission_energy_multiplier = 1.0
		emit_signal("deactivated")
	if _mesh_instance:
		_mesh_instance.mesh.material = mat
