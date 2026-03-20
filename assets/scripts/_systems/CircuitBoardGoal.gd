## CircuitBoardGoal
## A goal zone that looks like a circuit board rather than a transparent green plane.
## Same game logic as GoalZone: when the player robot enters, the level is complete.
## Used in levels where the goal should be visually distinct from sand crystals.

extends Area3D

signal player_reached_goal


func _ready() -> void:
	_build_mesh()
	_build_collision()
	body_entered.connect(_on_body_entered)


func _build_mesh() -> void:
	# Dark green PCB base
	var board := BoxMesh.new()
	board.size = Vector3(5.0, 0.07, 5.0)
	var board_mat := StandardMaterial3D.new()
	board_mat.albedo_color = Color(0.04, 0.28, 0.07, 1.0)
	board_mat.metallic = 0.3
	board_mat.roughness = 0.5
	board_mat.emission_enabled = true
	board_mat.emission = Color(0.0, 0.5, 0.1)
	board_mat.emission_energy_multiplier = 0.4
	board.material = board_mat
	var board_mi := MeshInstance3D.new()
	board_mi.mesh = board
	board_mi.position.y = 0.21
	add_child(board_mi)

	# Gold metallic border ring (slightly larger, slightly lower)
	var border := BoxMesh.new()
	border.size = Vector3(5.4, 0.04, 5.4)
	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.75, 0.6, 0.08, 1.0)
	border_mat.metallic = 0.9
	border_mat.roughness = 0.25
	border_mat.emission_enabled = true
	border_mat.emission = Color(0.6, 0.45, 0.05)
	border_mat.emission_energy_multiplier = 0.6
	border.material = border_mat
	var border_mi := MeshInstance3D.new()
	border_mi.mesh = border
	border_mi.position.y = 0.185
	add_child(border_mi)


func _build_collision() -> void:
	var box := BoxShape3D.new()
	box.size = Vector3(5.0, 0.5, 5.0)
	var col := CollisionShape3D.new()
	col.shape = box
	add_child(col)


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		get_tree().call_group("game_manager", "goal_reached")
		emit_signal("player_reached_goal")
