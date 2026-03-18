extends Area3D

signal player_reached_goal

func _ready() -> void:
	_build_mesh()
	_build_collision()
	body_entered.connect(_on_body_entered)

func _build_mesh() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(3.5, 3.5)

	var mat := StandardMaterial3D.new()
	mat.albedo_color     = Color(0.2, 1.0, 0.4, 0.6)
	mat.transparency     = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission         = Color(0.1, 0.8, 0.2)
	mat.emission_energy_multiplier = 0.8

	plane.material = mat

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = plane
	mesh_instance.position.y = 0.21
	add_child(mesh_instance)

func _build_collision() -> void:
	var box := BoxShape3D.new()
	box.size = Vector3(3.5, 0.5, 3.5)
	var col := CollisionShape3D.new()
	col.shape = box
	add_child(col)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		get_tree().call_group("game_manager", "goal_reached")
		emit_signal("player_reached_goal")
