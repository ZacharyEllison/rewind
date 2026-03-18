## HUD - Flat-screen overlay showing sand crystals and ghost recording slots.
extends CanvasLayer

# Node references — built programmatically in _build_ui()
var _crystal_label: Label
var _ghost_label: Label
var _attempt_label: Label


func _ready() -> void:
	_build_ui()
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm:
		if gm.has_signal("sand_crystal_collected"):
			gm.sand_crystal_collected.connect(_on_crystal_collected)
		if gm.has_signal("ghost_slots_changed"):
			gm.ghost_slots_changed.connect(_on_ghost_slots_changed)
		if gm.has_signal("recording_started"):
			gm.recording_started.connect(_on_recording_started)
	_refresh_labels()


func _build_ui() -> void:
	layer = 10  # Render above everything

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_bottom = -20
	panel.offset_top = -90   # enough height for the labels

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.65)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	panel.add_child(hbox)

	_attempt_label = _make_label("Run  #1", Color(0.9, 0.9, 0.9))
	hbox.add_child(_attempt_label)

	hbox.add_child(_make_separator())

	_crystal_label = _make_label("◆  0", Color(1.0, 0.85, 0.2))
	hbox.add_child(_crystal_label)

	hbox.add_child(_make_separator())

	_ghost_label = _make_label("👻  0 / 1", Color(0.7, 0.9, 1.0))
	hbox.add_child(_ghost_label)


func _make_label(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	return lbl


func _make_separator() -> VSeparator:
	var sep := VSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(1, 1, 1, 0.25)
	sep_style.content_margin_left = 1
	sep_style.content_margin_right = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	return sep


func _on_crystal_collected(count: int) -> void:
	_crystal_label.text = "◆  %d" % count


func _on_ghost_slots_changed(used: int, max_slots: int) -> void:
	_ghost_label.text = "👻  %d / %d" % [used, max_slots]


func _on_recording_started(count: int, _duration: float) -> void:
	_attempt_label.text = "Run  #%d" % count


func _refresh_labels() -> void:
	_crystal_label.text = "◆  0"
	_ghost_label.text = "👻  0 / 1"
	_attempt_label.text = "Run  #1"
