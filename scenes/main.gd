## main - Scene root: wires GameManager, RobotCharacter, and GhostRobot together.
## Also handles XR / flat-screen fallback: if OpenXR fails to initialize (no
## headset connected), a regular Camera3D is activated so the game is visible
## on desktop, and XR rendering is disabled to prevent error spam.

extends Node3D

func _ready() -> void:
	var game_manager := $GameManager
	var robot := $RobotCharacter
	var ghost := $GhostRobot

	game_manager.set_robot(robot)

	# When a rewind is triggered, start ghost playback
	game_manager.rewinding_started.connect(func(_position_count):
		ghost.start_playback(game_manager.recorded_positions, game_manager.recorded_animations)
	)

	# When ghost finishes playing back, mark rewind complete in GameManager.
	# complete_rewind() clears is_rewinding and emits rewind_completed internally,
	# avoiding direct property mutation and bare emit_signal calls from outside the class.
	ghost.playback_finished.connect(func():
		game_manager.complete_rewind()
	)

	# Clean up ghost if rewind is cancelled / new attempt starts
	game_manager.rewind_completed.connect(func():
		ghost.stop_playback()
	)

	_setup_xr_or_fallback()


func _setup_xr_or_fallback() -> void:
	# StartXR (godot-xr-tools) drives XR initialisation.  We listen to its
	# xr_failed_to_initialize signal so we know when to switch to flat-screen
	# mode.  If the node is absent for some reason we fall back immediately.
	var start_xr := get_node_or_null("StartXR")
	if start_xr and start_xr.has_signal("xr_failed_to_initialize"):
		start_xr.xr_failed_to_initialize.connect(_on_xr_failed_to_initialize)
	else:
		# No StartXR node — activate flat camera straight away.
		_activate_flat_camera()


func _on_xr_failed_to_initialize() -> void:
	# OpenXR could not find a headset.  Silence XR rendering and show the
	# flat-screen fallback camera so the game is still playable on desktop.
	get_viewport().use_xr = false
	_activate_flat_camera()


func _activate_flat_camera() -> void:
	var cam: Camera3D = get_node_or_null("FallbackCamera")
	if cam:
		cam.make_current()
		print("Main: XR unavailable — FallbackCamera activated for desktop play.")
	else:
		push_warning("Main: FallbackCamera node not found; scene will have no active camera.")
