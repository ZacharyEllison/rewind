## GameManager - Core game state and time rewind system

extends Node

# Signals
signal robot_moved
signal recording_started(count: int, duration: float)
signal recording_stopped
signal rewinding_started(duration: float)
signal rewind_completed
signal attempt_completed
signal sand_crystal_collected(count: int)

# Game state
const MAX_ATTEMPT_TIME: float = 30.0
const CRYSTAL_SAND_VALUE: float = 30.0

var current_attempt_count: int = 0
var current_attempt_duration: float = 0.0
var is_recording: bool = false
var is_rewinding: bool = false
var is_game_paused: bool = false
var current_level: int = 1

# Sand system
var sand_crystal_count: int = 1
var max_rewind_seconds: float = 30.0

# References
var robot_node: Node
var recorded_positions: Array[Vector3] = []

func _ready() -> void:
    _initialize_game()
    print("GameManager Ready - Max Attempt Time: %0.0f seconds" % MAX_ATTEMPT_TIME)

func _initialize_game() -> void:
    current_attempt_count = 0
    sand_crystal_count = 1
    max_rewind_seconds = 30.0
    _update_sand_system()

func _update_sand_system() -> void:
    var level_crystals: Dictionary = {
        1: 1,
        3: 2,
        5: 3,
        7: 4,
        9: 5
    }
    
    var crystals: int = level_crystals.get(current_level, 1)
    sand_crystal_count = crystals
    max_rewind_seconds = CRYSTAL_SAND_VALUE * float(crystals)
    
    print("Sand System - Level: %d, Crystals: %d, Max Rewind: %0.f seconds" % [
        current_level, sand_crystal_count, max_rewind_seconds
    ])

# Recording functions
func start_recording() -> void:
    is_recording = true
    current_attempt_count += 1
    current_attempt_duration = 0.0
    recorded_positions.clear()
    
    emit_signal("recording_started", current_attempt_count, MAX_ATTEMPT_TIME)
    print("Recording started - Attempt #%d, Max time: %0.fs" % [
        current_attempt_count, MAX_ATTEMPT_TIME
    ])

func _process(delta: float) -> void:
    if is_recording and robot_node:
        current_attempt_duration += delta
        
        # Record robot position at intervals
        if current_attempt_duration < MAX_ATTEMPT_TIME:
            if current_attempt_duration % 0.1 < delta:
                recorded_positions.append(robot_node.global_position)
        
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
    if !is_recording && recorded_positions.is_empty():
        print("ERROR: Cannot rewind - no recording or already rewinding")
        return
    
    is_recording = false
    is_rewinding = true
    
    emit_signal("rewinding_started", recorded_positions.size())
    print("Rewind triggered - Playback %d positions" % recorded_positions.size())

func start_new_attempt() -> void:
    is_rewinding = false
    is_recording = false
    current_attempt_duration = 0.0
    recorded_positions.clear()
    _reset_robot_position()
    
    print("New attempt started")

func retry_current_attempt() -> void:
    is_recording = false
    is_rewinding = false
    is_game_paused = false
    _reset_robot_position()
    print("Current attempt retried")

func _reset_robot_position() -> void:
    if robot_node:
        robot_node.global_position = Vector3.ZERO
        # Also reset rotation if needed
        # robot_node.global_rotation_degrees = Vector3.ZERO

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

func get_max_rewind_seconds() -> float:
    return max_rewind_seconds

func add_sand_crystal() -> void:
    sand_crystal_count += 1
    max_rewind_seconds = CRYSTAL_SAND_VALUE * float(sand_crystal_count)
    emit_signal("sand_crystal_collected", sand_crystal_count)
