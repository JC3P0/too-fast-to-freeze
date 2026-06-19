class_name DirectionalStrategy
extends InputStrategy

## Directional drag/angle control system — ported from WildJam76 newcontrols branch.
## Sets GlobalState.player_direction (Vector3) and GlobalState.player_current_speed
## each frame. obstacle_move.gd reads both X and Z components.
##
## TODO (next issue): implement IDLE / TURNING / RELEASED state logic and pump mechanic.

func process_input(_player: CharacterBody3D, _delta: float) -> void:
	pass

func handle_input_event(_player: CharacterBody3D, _event: InputEvent) -> void:
	pass

func get_strategy_name() -> String:
	return "Directional"
