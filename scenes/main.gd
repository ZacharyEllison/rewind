## main - Scene root: wires GameManager, RobotCharacter, and GhostRobot together.
## Also handles XR / flat-screen fallback: if OpenXR fails to initialize (no
## headset connected), a regular Camera3D is activated so the game is visible
## on desktop, and XR rendering is disabled to prevent error spam.

extends Node3D

## Pool of ghost nodes, one per available ghost slot. Index 0 is always $GhostRobot.
var _ghost_pool: Array[Node] = []

## Tracks how many ghosts are currently playing back; when this reaches 0,
## rewind is considered complete.
var _ghosts_playing: int = 0

## Currently loaded level scene instance.
var _current_level_scene: Node = null

func _ready() -> void:
	var game_manager := $GameManager
	var robot := $RobotCharacter

	game_manager.set_robot(robot)

	# Load the starting level.
	_load_level(game_manager.current_level)
	game_manager.level_changed.connect(_on_level_changed)

	# Build the initial ghost pool (1 slot: the existing $GhostRobot).
	_rebuild_ghost_pool()

	# When a new crystal is collected, expand the pool by one ghost.
	game_manager.sand_crystal_collected.connect(func(_count):
		_rebuild_ghost_pool()
	)

	# When a rewind is triggered, start playback on every ghost that has a run.
	game_manager.rewinding_started.connect(func(_position_count):
		_ghosts_playing = 0
		for i in range(game_manager.past_runs.size()):
			if i >= _ghost_pool.size():
				break
			var run = game_manager.past_runs[i]
			_ghost_pool[i].start_playback(run["positions"], run["animations"])
			_ghosts_playing += 1
	)

	# When all ghosts finish, mark rewind complete in GameManager.
	# complete_rewind() clears is_rewinding and emits rewind_completed internally.
	# Individual ghost connections are set up inside _rebuild_ghost_pool().

	# Stop all ghosts when rewind is cancelled or a new attempt starts.
	game_manager.rewind_completed.connect(func():
		for ghost in _ghost_pool:
			ghost.stop_playback()
	)

	_setup_xr_or_fallback()


## Rebuilds the ghost pool to match game_manager.max_ghost_slots.
## Slot 0 is always the original $GhostRobot node; additional slots are
## duplicates appended as children of this scene root.
func _rebuild_ghost_pool() -> void:
	var game_manager := $GameManager
	var base_ghost := $GhostRobot

	# Stop and disconnect any ghosts beyond the base node before clearing.
	for i in range(1, _ghost_pool.size()):
		var old_ghost: Node = _ghost_pool[i]
		if old_ghost.has_signal("playback_finished"):
			# Disconnect all connections from this ghost's playback_finished to _on_ghost_playback_finished.
			if old_ghost.playback_finished.is_connected(_on_ghost_playback_finished):
				old_ghost.playback_finished.disconnect(_on_ghost_playback_finished)
		old_ghost.stop_playback()
		old_ghost.queue_free()

	_ghost_pool.clear()

	# Disconnect base ghost's signal before re-connecting to avoid duplicates.
	if base_ghost.playback_finished.is_connected(_on_ghost_playback_finished):
		base_ghost.playback_finished.disconnect(_on_ghost_playback_finished)

	# Slot 0: the original scene ghost.
	base_ghost.playback_finished.connect(_on_ghost_playback_finished)
	_ghost_pool.append(base_ghost)

	# Slots 1..max_ghost_slots-1: duplicates added as siblings of the base ghost.
	for _i in range(1, game_manager.max_ghost_slots):
		var new_ghost: Node = base_ghost.duplicate()
		add_child(new_ghost)
		new_ghost.playback_finished.connect(_on_ghost_playback_finished)
		_ghost_pool.append(new_ghost)

	print("Ghost pool rebuilt - %d slot(s)" % _ghost_pool.size())


## Called whenever any ghost finishes its playback.
## When all active ghosts are done, signals GameManager that the rewind is complete.
func _on_ghost_playback_finished() -> void:
	_ghosts_playing -= 1
	if _ghosts_playing <= 0:
		_ghosts_playing = 0
		$GameManager.complete_rewind()


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


## Unload the current level and load the scene for the given level_id.
func _load_level(level_id: int) -> void:
	var level_container := $LevelContainer
	# Free the previous level.
	if _current_level_scene:
		_current_level_scene.queue_free()
		_current_level_scene = null

	var level_paths: Dictionary = {
		0: "res://scenes/level_00.tscn",
		1: "res://scenes/level_01.tscn",
	}
	if not level_id in level_paths:
		push_warning("Main: no level scene registered for level_id %d" % level_id)
		return

	var packed: PackedScene = load(level_paths[level_id])
	if not packed:
		push_error("Main: failed to load level scene: %s" % level_paths[level_id])
		return

	_current_level_scene = packed.instantiate()
	level_container.add_child(_current_level_scene)

	# Set the robot's spawn position from the level's SpawnPoint node (if present).
	var spawn_node := _current_level_scene.get_node_or_null("SpawnPoint") as Node3D
	var robot := $RobotCharacter
	var spawn_pos: Vector3 = spawn_node.global_position if spawn_node else Vector3(0, 0.5, 0)
	robot.global_position = spawn_pos
	robot.set("spawn_position", spawn_pos)
	print("Main: loaded level %d, robot spawn at %s" % [level_id, str(spawn_pos)])


## Called when GameManager emits level_changed; transitions to the new level.
func _on_level_changed(level_id: int) -> void:
	_load_level(level_id)
	var game_manager := $GameManager
	game_manager.start_new_attempt()
	game_manager.start_recording()
