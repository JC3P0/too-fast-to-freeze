extends Control

@onready var level_loader = $"../LevelLoader"
@onready var distance_label = $GameOver/VBoxContainer/distance

func show_game_over():
	visible = true
	distance_label.text = "Distance: " + str(int(GlobalState.total_distance))
	get_tree().paused = true
	$GameOver/VBoxContainer/Restart.grab_focus()

func _on_restart_pressed() -> void:
	visible = false
	GlobalState.player_speed = 0
	GlobalState.total_distance = 0
	level_loader.restart_level()
