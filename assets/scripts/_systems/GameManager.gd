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
signal attempt_completed
signal sand_crystal_collected(count: int)

## Game state
const MAX_ATTEMPT_TIME: float = 30.0
const CRYSTAL_SAND_VALUE: float = 30.0

var current_attempt_count: int = 0
var current_attempt_duration: float = 0.0
var is_recording: bool = false
var is_rewinding: bool = false
var is_game_paused: bool = false
var current_level: int = 1

## Sand system
var sand_crystal_count: int = 1
var max_rewind_seconds: float = 0.0

## References
var robot_node: Node
var recorded_positions: Array[Vector3] = []
var recorded_animations: Array[String] = []

## Elapsed time since the last position sample was recorded.
## Used instead of floating-point modulo to reliably fire at RECORD_INTERVAL.
var _record_accumulator: float = 0.0

func _ready() -> void:
    _initialize_game()
    print("GameManager Ready - Max Attempt Time: %0.0f seconds" % MAX_ATTEMPT_TIME)

func _initialize_game() -> void:
    current_attempt_count = 0
    sand_crystal_count = 1
    _update_sand_system()

func _update_sand_system() -> void:
    var level_crystals: Dictionary = {
        1: 1,
        3: 2,
        5: 3,
        7: 4,
        9: 5
    }
    
    sand_crystal_count = level_crystals.get(current_level, 1)
    max_rewind_seconds = CRYSTAL_SAND_VALUE * float(sand_crystal_count)
    
    print("Sand System - Level: %d, Crystals: %d, Max Rewind: %0.f seconds" % [
        current_level, sand_crystal_count, max_rewind_seconds
    ])

## Recording functions
func start_recording() -> void:
    is_recording = true
    current_attempt_count += 1
    current_attempt_duration = 0.0
    _record_accumulator = 0.0
    recorded_positions.clear()
    recorded_animations.clear()

    emit_signal("recording_started", current_attempt_count, MAX_ATTEMPT_TIME)
    print("Recording started - Attempt #%d, Max time: %0.fs" % [
        current_attempt_count, MAX_ATTEMPT_TIME
    ])

func _process(delta: float) -> void:
    if is_recording and robot_node:
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
                recorded_animations.append(_derive_animation_state(velocity, on_floor))
        
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
    # Guard: block if already rewinding (prevents double-trigger) or nothing to play back.
    if is_rewinding or recorded_positions.is_empty():
        print("ERROR: Cannot rewind - already rewinding or no positions recorded")
        return

    is_recording = false
    is_rewinding = true

    emit_signal("rewinding_started", recorded_positions.size())
    print("Rewind triggered - Playback %d positions" % recorded_positions.size())

func start_new_attempt() -> void:
    is_rewinding = false
    is_recording = false
    current_attempt_duration = 0.0
    _record_accumulator = 0.0
    recorded_positions.clear()
    recorded_animations.clear()
    _reset_robot_position()
    
    print("New attempt started")

func retry_current_attempt() -> void:
    is_recording = false
    is_rewinding = false
    is_game_paused = false
    _reset_robot_position()
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
    print("Robot set - ", str(robot_node))

func _update_level(level: int) -> void:
    current_level = level
    _update_sand_system()

func get_robot_node() -> Node:
    return robot_node

func is_recording_active() -> bool:
    return is_recording

func is_rewinding_active() -> bool:
    return is_rewinding

## Called by GhostRobot (via main.gd) when playback finishes.
## Clears the rewinding flag and fires rewind_completed so listeners can react.
func complete_rewind() -> void:
    is_rewinding = false
    emit_signal("rewind_completed")

func get_max_rewind_seconds() -> float:
    return max_rewind_seconds

func add_sand_crystal() -> void:
    sand_crystal_count += 1
    max_rewind_seconds = CRYSTAL_SAND_VALUE * float(sand_crystal_count)
    emit_signal("sand_crystal_collected", sand_crystal_count)

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
