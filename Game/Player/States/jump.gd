extends Node

var player
var jump_height = 2.0
var jump_duration = 1.0
var current_jump_time = 0.0

func set_player(player_instance):
	player = player_instance

func enter_state():
	print("entered: jump state")
	player.animation_player.play("Jump")	
	current_jump_time = 0.0

func exit_state():
	print("exiting jump state")

func handle_input(event):
	if Input.is_action_pressed("Turn_Right"):
		player.turn_direction = 1

	if Input.is_action_pressed("Turn_Left"):
		player.turn_direction = -1

func process_state(delta):
	player.player_state_manager.player_helper.adjust_player_speed(GlobalState.player_speed + 1, (2), delta)
	player.player_state_manager.player_helper.move_player(3, player, delta)
	player.player_state_manager.player_helper.rotate_player((17.5), (2.5), player, delta)


	if current_jump_time < jump_duration:
		var jump_progress = current_jump_time / jump_duration
		var vertical_offset = sin(jump_progress * PI) * jump_height
		player.position.y = vertical_offset
		current_jump_time += delta
	else:
		print("jump completed!")
		player.player_state_manager.set_state("Idle")
