extends Node3D

func _ready() -> void:
	var game_manager := $GameManager
	var robot := $RobotCharacter
	var ghost := $GhostRobot

	game_manager.set_robot(robot)

	# When a rewind is triggered, start ghost playback
	game_manager.rewinding_started.connect(func(_duration):
		ghost.start_playback(game_manager.recorded_positions)
	)

	# When ghost finishes playing back, mark rewind complete in GameManager
	ghost.playback_finished.connect(func():
		game_manager.is_rewinding = false
		game_manager.emit_signal("rewind_completed")
	)

	# Clean up ghost if rewind is cancelled / new attempt starts
	game_manager.rewind_completed.connect(func():
		ghost.stop_playback()
	)
