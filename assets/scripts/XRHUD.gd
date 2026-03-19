extends Node3D

# Default local position when attached to XRCamera3D: (0, -0.18, -0.6)
# This is set in the .tscn file, not here.

@export var game_manager_path: NodePath

var _run_label: Label3D
var _crystal_label: Label3D
var _ghost_label: Label3D

var _game_manager = null


func _ready() -> void:
	_build_background()
	_build_labels()
	_connect_game_manager()


func _build_background() -> void:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.6, 0.12)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0, 0, 0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	plane.material = mat
	mesh_instance.mesh = plane
	mesh_instance.position = Vector3(0, 0, 0)
	add_child(mesh_instance)


func _make_label(text: String, pos: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.pixel_size = 0.001
	label.font_size = 28
	label.outline_size = 6
	label.modulate = Color(1, 1, 1, 1)
	label.outline_modulate = Color(0, 0, 0, 1)
	label.no_depth_test = true
	label.render_priority = 1
	add_child(label)
	return label


func _build_labels() -> void:
	_run_label     = _make_label("Run #1",   Vector3(-0.18, 0, 0.001))
	_crystal_label = _make_label("\u25C6 0",  Vector3(0,     0, 0.001))
	_ghost_label   = _make_label("G 0/1", Vector3(0.18, 0, 0.001))


func _connect_game_manager() -> void:
	_game_manager = get_tree().get_first_node_in_group("game_manager")

	if _game_manager == null:
		push_warning("XRHUD: No node found in group 'game_manager'. HUD signals will not be connected.")
		return

	if _game_manager.has_signal("recording_started"):
		_game_manager.recording_started.connect(_on_recording_started)

	if _game_manager.has_signal("sand_crystal_collected"):
		_game_manager.sand_crystal_collected.connect(_on_sand_crystal_collected)

	if _game_manager.has_signal("ghost_slots_changed"):
		_game_manager.ghost_slots_changed.connect(_on_ghost_slots_changed)

	if _game_manager.has_signal("rewind_completed"):
		_game_manager.rewind_completed.connect(_on_rewind_completed)


# Signal handlers

func _on_recording_started(count: int, _duration: float) -> void:
	_run_label.text = "Run #%d" % count


func _on_sand_crystal_collected(count: int) -> void:
	_crystal_label.text = "\u25C6 %d" % count


func _on_ghost_slots_changed(used: int, max_slots: int) -> void:
	_ghost_label.text = "G %d/%d" % [used, max_slots]


func _on_rewind_completed() -> void:
	if _game_manager == null:
		return
	var used: int = _game_manager.past_runs.size()
	var max_slots: int = _game_manager.max_ghost_slots
	_ghost_label.text = "G %d/%d" % [used, max_slots]
