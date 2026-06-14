extends Control

@onready var speed_label: Label = $PanelContainer/VBoxContainer/SpeedContainer/SpeedCurrent
@onready var distance_label: Label = $PanelContainer/VBoxContainer/DistanceContainer/DistanceCurrent
@onready var freeze_timer = $FreezeTimer
@onready var freeze_progress_bar = $FreezeProgressBar
@onready var percentage_of_time
@onready var game_over_scene = $"../../../GameOverScreen"
var player: Node = null

var coffee_time = 5.0

func _ready() -> void:
	freeze_timer.connect("timeout", Callable(self, "_on_stop_freeze_timer_timeout"))

func _process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	speed_label.text = str(int(player.player_speed))
	distance_label.text = str(int(GlobalState.total_distance))
	if freeze_timer.get_time_left() > 0:
		freeze_progress_bar.value = 60 - freeze_timer.time_left

func _on_stop_freeze_timer_timeout():
	game_over_scene.show_game_over()
	print("game_over!")

func add_freeze_time():
	var new_time = freeze_timer.time_left + coffee_time
	if new_time > 60:
		new_time = 60
	freeze_timer.wait_time = new_time
	freeze_timer.start()
