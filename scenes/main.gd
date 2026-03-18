## main - Scene root: wires GameManager, RobotCharacter, and GhostRobot together.

extends Node3D

func _ready() -> void:
	var game_manager := $GameManager
	var robot := $RobotCharacter
	var ghost := $GhostRobot

	game_manager.set_robot(robot)

	# When a rewind is triggered, start ghost playback
	game_manager.rewinding_started.connect(func(_position_count):
		ghost.start_playback(game_manager.recorded_positions)
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
