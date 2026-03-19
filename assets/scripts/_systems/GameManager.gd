## GameManager - Core game state and time rewind system

extends Node

## How often (in seconds) the robot's position is sampled during recording.
## GhostRobot.SAMPLE_INTERVAL must match this value.
const RECORD_INTERVAL: float = 0.1

## Signals
signal robot_moved
signal recording_started(count: int, duration: float)
signal recording_stopped
signal rewinding_started(position_count: int)
signal rewind_completed
signal ghost_playback_requested
signal attempt_completed
signal sand_crystal_collected(count: int)
signal ghost_slots_changed(slots_used: int, slots_max: int)
signal level_changed(level_id: int)
signal new_attempt_started

## Game state
const MAX_ATTEMPT_TIME: float = 30.0
const CRYSTAL_SAND_VALUE: float = 30.0

var current_attempt_count: int = 0
var current_attempt_duration: float = 0.0
var is_recording: bool = false
var is_rewinding: bool = false
var is_game_paused: bool = false
var current_level: int = 0

## Sand / ghost system
var sand_crystal_count: int = 0
var max_rewind_seconds: float = 0.0
var max_ghost_slots: int = 1

## Past runs stored as Dictionaries: {positions: Array[Vector3], animations: Array[String]}
var past_runs: Array = []

## References
var robot_node: Node
var recorded_positions: Array[Vector3] = []
var recorded_animations: Array[String] = []

## Elapsed time since the last position sample was recorded.
## Used instead of floating-point modulo to reliably fire at RECORD_INTERVAL.
var _record_accumulator: float = 0.0
var _robot_animation_controller: Node = null

func _ready() -> void:
	add_to_group("game_manager")
	_initialize_game()
	print("GameManager Ready - Max Attempt Time: %0.0f seconds" % MAX_ATTEMPT_TIME)

func _initialize_game() -> void:
	current_attempt_count = 0
	current_attempt_duration = 0.0
	is_recording = false
	is_rewinding = false
	is_game_paused = false
	sand_crystal_count = 0
	max_ghost_slots = 1
	past_runs.clear()
	recorded_positions.clear()
	recorded_animations.clear()
	max_rewind_seconds = MAX_ATTEMPT_TIME * max_ghost_slots

## Recording functions
func start_recording() -> void:
	is_recording = true
	is_rewinding = false
	current_attempt_count += 1
	_clear_current_recording()

	emit_signal("recording_started", current_attempt_count, MAX_ATTEMPT_TIME)
	print("Recording started - Attempt #%d, Max time: %0.fs" % [
		current_attempt_count, MAX_ATTEMPT_TIME
	])

func _process(delta: float) -> void:
	if is_recording and robot_node:
		if not _robot_animation_controller or not is_instance_valid(_robot_animation_controller):
			_robot_animation_controller = _find_robot_animation_controller()
		current_attempt_duration += delta

		# Record robot position at fixed intervals using an accumulator.
		# The old approach (current_attempt_duration % RECORD_INTERVAL < delta)
		# was unreliable because floating-point modulo can skip the threshold
		# between frames when delta is large or accumulated precision is low.
		if current_attempt_duration < MAX_ATTEMPT_TIME:
			_record_accumulator += delta
			if _record_accumulator >= RECORD_INTERVAL:
				_record_accumulator -= RECORD_INTERVAL
				recorded_positions.append(robot_node.global_position)
				var body := robot_node as CharacterBody3D
				var on_floor := body.is_on_floor() if body else true
				var velocity := body.velocity if body else Vector3.ZERO
				recorded_animations.append(_get_recorded_animation_state(velocity, on_floor))

		# Auto-stop at max time
		if current_attempt_duration >= MAX_ATTEMPT_TIME:
			stop_recording()

func stop_recording() -> void:
	is_recording = false

	print("Recording stopped. Recorded %d positions over %0.f seconds" % [
		recorded_positions.size(), current_attempt_duration
	])

	emit_signal("recording_stopped")

func trigger_rewind() -> void:
	if recorded_positions.is_empty():
		print("ERROR: Cannot rewind - no positions recorded")
		return

	stop_recording()
	_store_current_run()
	_begin_next_attempt_with_ghosts()
	print("Rewind triggered - Playback %d retained run(s), next live attempt started" % past_runs.size())

func start_new_attempt() -> void:
	is_recording = false
	is_rewinding = false
	is_game_paused = false
	_clear_current_recording()
	past_runs.clear()
	_reset_robot_position()
	emit_signal("new_attempt_started")
	emit_signal("ghost_slots_changed", 0, max_ghost_slots)
	emit_signal("ghost_playback_requested")
	print("New attempt started")

func retry_current_attempt() -> void:
	is_recording = false
	is_rewinding = false
	is_game_paused = false
	_clear_current_recording()
	_reset_robot_position()
	emit_signal("new_attempt_started")
	emit_signal("ghost_slots_changed", past_runs.size(), max_ghost_slots)
	emit_signal("ghost_playback_requested")
	start_recording()
	print("Current attempt retried")

func _reset_robot_position() -> void:
	if not robot_node:
		return
	# Use the robot's own spawn_position if available, so reset lands on the platform surface.
	var spawn: Vector3 = robot_node.get("spawn_position") if robot_node.get("spawn_position") != null else Vector3(0, 0.5, 0)
	robot_node.global_position = spawn
	if robot_node is CharacterBody3D:
		(robot_node as CharacterBody3D).velocity = Vector3.ZERO

func set_robot(node: Node) -> void:
	robot_node = node
	_robot_animation_controller = _find_robot_animation_controller()
	print("Robot set - ", str(robot_node))

func _update_level(level: int) -> void:
	current_level = level
	max_rewind_seconds = MAX_ATTEMPT_TIME * max_ghost_slots
	emit_signal("level_changed", current_level)

func get_robot_node() -> Node:
	return robot_node

func is_recording_active() -> bool:
	return is_recording

func is_rewinding_active() -> bool:
	return is_rewinding

## Compatibility shim for older UI/scripts that still listen for rewind_completed.
func complete_rewind() -> void:
	is_rewinding = false
	emit_signal("rewind_completed")

func get_max_rewind_seconds() -> float:
	return max_rewind_seconds

func add_sand_crystal() -> void:
	sand_crystal_count += 1
	max_ghost_slots += 1
	max_rewind_seconds = MAX_ATTEMPT_TIME * max_ghost_slots
	emit_signal("sand_crystal_collected", sand_crystal_count)
	emit_signal("ghost_slots_changed", past_runs.size(), max_ghost_slots)
	print("Sand crystal collected - Count: %d, Ghost slots: %d" % [
		sand_crystal_count, max_ghost_slots
	])

func goal_reached() -> void:
	if is_recording:
		stop_recording()
	emit_signal("attempt_completed")
	current_level += 1
	emit_signal("level_changed", current_level)

## Derives the animation state name from velocity and floor contact,
## using the same thresholds as RobotAnimationController.
func _derive_animation_state(velocity: Vector3, on_floor: bool) -> String:
	const IDLE_THRESHOLD: float = 0.5
	const RUN_THRESHOLD: float = 4.0
	var horizontal_speed := Vector3(velocity.x, 0.0, velocity.z).length()
	if not on_floor:
		return "jump" if velocity.y > 0.0 else "fall"
	elif horizontal_speed > RUN_THRESHOLD:
		return "run"
	elif horizontal_speed > IDLE_THRESHOLD:
		return "walk"
	else:
		return "idle"


func _get_recorded_animation_state(velocity: Vector3, on_floor: bool) -> String:
	if _robot_animation_controller and _robot_animation_controller.has_method("get_current_animation_state"):
		var state := _robot_animation_controller.call("get_current_animation_state") as String
		if not state.is_empty():
			return state
	return _derive_animation_state(velocity, on_floor)


func _find_robot_animation_controller() -> Node:
	if not robot_node:
		return null
	return _find_node_with_method(robot_node, "get_current_animation_state")


func _find_node_with_method(node: Node, method_name: String) -> Node:
	if node.has_method(method_name):
		return node
	for child in node.get_children():
		var found := _find_node_with_method(child, method_name)
		if found:
			return found
	return null


func _clear_current_recording() -> void:
	current_attempt_duration = 0.0
	_record_accumulator = 0.0
	recorded_positions.clear()
	recorded_animations.clear()


func _store_current_run() -> void:
	var run := {
		"positions": recorded_positions.duplicate(),
		"animations": recorded_animations.duplicate()
	}
	past_runs.push_back(run)
	while past_runs.size() > max_ghost_slots:
		past_runs.pop_front()


func _begin_next_attempt_with_ghosts() -> void:
	is_rewinding = false
	is_game_paused = false
	_clear_current_recording()
	_reset_robot_position()
	emit_signal("new_attempt_started")
	emit_signal("ghost_slots_changed", past_runs.size(), max_ghost_slots)
	emit_signal("ghost_playback_requested")
	start_recording()
