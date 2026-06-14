extends CharacterBody3D

@onready var player_state_manager = $Player_state_manager
@onready var turn_direction = 0
@onready var animation_player: AnimationPlayer = $Player4/AnimationPlayer
@onready var idle_particles = $snow_trail_idle
@onready var soft_turn_particles = $soft_trail_particles
@onready var hard_turn_particles = $hard_trail_particles

## Flyweight resource holding all player movement stats.
## Assign a PlayerStatsResource .tres in the Inspector.
@export var stats: PlayerStatsResource

@onready var control: Control = $"../Control"

var player_speed: float = 0.0
var body_to_delete

func _ready() -> void:
	add_to_group("Player")
	player_state_manager.initialize(self)
	player_state_manager.player_helper.init_particles(self)
	player_state_manager.set_state("Idle")

func _input(event):
	if player_state_manager.current_state_name == "Vuln":
		return

	if player_state_manager.current_state:
		player_state_manager.current_state.handle_input(event)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	#
	# adds the distance to the current distance for total distance
	#var distance_this_frame = round(GlobalState.player_speed * delta)
	var distance_this_frame = (player_speed * delta) / 2
	GlobalState.total_distance += distance_this_frame


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Obstacle"):
		player_state_manager.set_state("Vuln")
		$HurtTimer.start()
		body_to_delete = body
		EventBus.player_hit.emit(body)

	if body.is_in_group("Coffee"):
		control.add_freeze_time()
		body.queue_free()

func _on_hurt_timer_timeout() -> void:
	body_to_delete.queue_free()
	
