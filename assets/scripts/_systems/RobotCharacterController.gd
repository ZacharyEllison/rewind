## RobotCharacterController
## Uses XR Tools CharacterBody3D for smooth robot movement

extends CharacterBody3D

# Movement settings
var move_speed: float = 2.5

# Input handling
var input_direction: Vector2 = Vector2.ZERO

# Recording system
var is_recording: bool = false
var recorded_positions: Array[Vector3] = []
var recording_time_elapsed: float = 0.0
const RECORDING_INTERVAL: float = 0.1

# References
var game_manager: Node

func _ready() -> void:
    # Get GameManager
    game_manager = get_tree().get_node_or_null("/root/GameManager")
    
    # Initialize robot position
    global_position = Vector3.ZERO
    print("RobotController Ready - Speed: %0.1f m/s" % move_speed)

func _physics_process(delta: float) -> void:
    # Handle movement input
    var move_velocity := _handle_input(delta)
    velocity := move_velocity
    move_and_slide()
    
    # Handle recording
    _handle_recording(delta)

func _handle_input(delta: float) -> Vector3:
    input_direction = Vector2.ZERO
    
    # Keyboard input (debug/testing)
    if Input.is_action_pressed("move_robot_forward"):
        input_direction.y = 1.0
    elif Input.is_action_pressed("move_robot_backward"):
        input_direction.y = -1.0
    
    if Input.is_action_pressed("move_robot_left"):
        input_direction.x = -1.0
    elif Input.is_action_pressed("move_robot_right"):
        input_direction.x = 1.0
    
    if input_direction.length() > 1.0:
        input_direction = input_direction.normalized()
    
    var camera := get_viewport().get_camera_3d()
    if camera:
        var forward_dir := camera.global_transform.basis.z.normalized()
        var right_dir := camera.global_transform.basis.x.normalized()
        
        var move_dir := forward_dir * (-input_direction.y) + right_dir * input_direction.x
        move_dir = move_dir.normalized()
        
        return move_dir * move_speed
    
    return Vector3.ZERO

func _handle_recording(delta: float) -> void:
    if is_recording:
        recording_time_elapsed += delta
        
        if recording_time_elapsed >= RECORDING_INTERVAL:
            recording_time_elapsed = 0.0
            recorded_positions.append(global_position)
            
            if recording_time_elapsed >= 30.0:
                stop_recording()
                if game_manager:
                    game_manager.recorded_stopped.emit()

func start_recording() -> void:
    is_recording = true
    recording_time_elapsed = 0.0
    recorded_positions.clear()
    
    if game_manager:
        game_manager.recorded_started.emit()

func stop_recording() -> void:
    is_recording = false
    
    if game_manager:
        game_manager.recorded_stopped.emit()

func get_recorded_positions() -> Array[Vector3]:
    return recorded_positions

func clear_recordings() -> void:
    recorded_positions.clear()
    recording_time_elapsed = 0.0
