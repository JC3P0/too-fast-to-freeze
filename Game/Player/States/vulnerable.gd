extends Node
var player
var vuln_timer: Timer

func set_player(player_instance):
	player = player_instance
	vuln_timer = Timer.new()
	vuln_timer.wait_time = 1.5  
	vuln_timer.one_shot = true
	vuln_timer.connect("timeout", Callable(self, "_on_vuln_timer_timeout"))
	player.add_child(vuln_timer)

func enter_state():
	player.animation_player.play("Hurt")
	print("entered: vulnerable state")
	player.player_speed = 0
	#player.turn_direction = player.player_state_manager.player_helper.determine_turn_direction(player.turn_direction)
	vuln_timer.start()

func exit_state():
	print("leaving: vulnerable state")

func handle_input(_event):
	pass
	#if Input.is_action_pressed("Turn_Right"):
		#player.turn_direction = 1
#
	#if Input.is_action_pressed("Turn_Left"):
		#player.turn_direction = -1

func process_state(delta):
	player.player_state_manager.player_helper.adjust_player_speed(player, 0, 0, delta)
	player.player_state_manager.player_helper.move_player(0, player, delta)
	player.player_state_manager.player_helper.rotate_player(17.5, 2.5, player, delta)

func _on_vuln_timer_timeout():
	player.player_state_manager.set_state("Idle")
