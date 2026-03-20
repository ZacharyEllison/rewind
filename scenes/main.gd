## main - Scene root: wires GameManager, RobotCharacter, and GhostRobot together.
## Also handles XR / flat-screen fallback: if OpenXR fails to initialize (no
## headset connected), a regular Camera3D is activated so the game is visible
## on desktop, and XR rendering is disabled to prevent error spam.

extends Node3D

## Pool of ghost nodes, one per available ghost slot. Index 0 is always $GhostRobot.
var _ghost_pool: Array[Node] = []

## Clean duplicate source captured before any playback starts, so new slots do
## not inherit live playback state from an active ghost.
var _ghost_template: Node = null

## Currently loaded level scene instance.
var _current_level_scene: Node = null
var _flat_cam_active: bool = false
var _player_spawn_transform: Transform3D = Transform3D.IDENTITY
var _has_player_spawn: bool = false

func _ready() -> void:
	var game_manager := $GameManager
	var robot := $RobotCharacter
	var base_ghost := $GhostRobot

	game_manager.set_robot(robot)
	_ghost_pool = [base_ghost]
	_ghost_template = base_ghost.duplicate()

	# Load the starting level.
	_load_level(game_manager.current_level)
	game_manager.level_changed.connect(_on_level_changed)
	game_manager.new_attempt_started.connect(_reset_player_to_level_spawn)

	_ensure_ghost_pool_size(game_manager.max_ghost_slots)
	game_manager.ghost_slots_changed.connect(_on_ghost_slots_changed)
	game_manager.ghost_playback_requested.connect(_on_ghost_playback_requested)

	_setup_xr_or_fallback()


## Grows or shrinks the reusable ghost pool to match the currently unlocked
## slot count without restarting any ghosts already in motion.
func _ensure_ghost_pool_size(desired_size: int) -> void:
	var target_size := maxi(desired_size, 1)
	var previous_size := _ghost_pool.size()
	while _ghost_pool.size() < target_size:
		var new_ghost: Node = _ghost_template.duplicate()
		add_child(new_ghost)
		_ghost_pool.append(new_ghost)
	while _ghost_pool.size() > target_size and _ghost_pool.size() > 1:
		var old_ghost: Node = _ghost_pool.pop_back()
		old_ghost.stop_playback()
		old_ghost.queue_free()
	if _ghost_pool.size() != previous_size:
		print("Ghost pool ready - %d slot(s)" % _ghost_pool.size())


func _stop_all_ghosts() -> void:
	for ghost in _ghost_pool:
		ghost.stop_playback()


func _on_ghost_slots_changed(_used: int, max_slots: int) -> void:
	_ensure_ghost_pool_size(max_slots)


func _on_ghost_playback_requested() -> void:
	var game_manager := $GameManager
	_ensure_ghost_pool_size(game_manager.max_ghost_slots)
	_stop_all_ghosts()

	for i in range(mini(game_manager.past_runs.size(), _ghost_pool.size())):
		var run: Dictionary = game_manager.past_runs[i]
		var positions: Array[Vector3] = []
		var animations: Array[String] = []
		positions.assign(run.get("positions", []))
		animations.assign(run.get("animations", []))
		_ghost_pool[i].start_playback(positions, animations)


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
		_flat_cam_active = true
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

	var player_spawn_node := _current_level_scene.get_node_or_null("PlayerSpawnPoint") as Node3D
	if player_spawn_node:
		_player_spawn_transform = player_spawn_node.global_transform
		_has_player_spawn = true
		_reset_player_to_level_spawn()
	else:
		_has_player_spawn = false

	print("Main: loaded level %d, robot spawn at %s, player spawn at %s" % [
		level_id,
		str(spawn_pos),
		str(_player_spawn_transform.origin if _has_player_spawn else $XROrigin3D.global_position)
	])


## Called when GameManager emits level_changed; transitions to the new level.
func _on_level_changed(level_id: int) -> void:
	_stop_all_ghosts()
	_load_level(level_id)
	var game_manager := $GameManager
	game_manager.start_new_attempt()
	game_manager.start_recording()


func _reset_player_to_level_spawn() -> void:
	if not _has_player_spawn:
		return

	var xr_origin := $XROrigin3D as XROrigin3D
	if not xr_origin:
		return

	xr_origin.global_transform = _player_spawn_transform


func _process(delta: float) -> void:
	if not _flat_cam_active:
		return
	var cam: Camera3D = get_node_or_null("FallbackCamera")
	if not cam:
		return
	var yaw := (float(Input.is_key_pressed(KEY_LEFT)) - float(Input.is_key_pressed(KEY_RIGHT))) * 1.5 * delta
	var pitch := (float(Input.is_key_pressed(KEY_UP)) - float(Input.is_key_pressed(KEY_DOWN))) * 1.0 * delta
	cam.rotate_y(yaw)
	cam.rotate_object_local(Vector3.RIGHT, pitch)
	# Clamp pitch
	var euler := cam.rotation
	euler.x = clamp(euler.x, deg_to_rad(-80), deg_to_rad(80))
	cam.rotation = euler

	# Keep the hourglass rig (child of XROrigin3D) tracking the robot in flat mode.
	var xr_origin := get_node_or_null("XROrigin3D") as Node3D
	var robot := get_node_or_null("RobotCharacter") as Node3D
	if xr_origin and robot:
		xr_origin.global_position = robot.global_position
