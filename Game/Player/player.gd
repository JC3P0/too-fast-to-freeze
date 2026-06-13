extends CharacterBody3D

@onready var player_state_manager = $Player_state_manager
@onready var turn_direction = 0
@onready var animation_player: AnimationPlayer = $Player4/AnimationPlayer
@onready var idle_particles = $snow_trail_idle
@onready var soft_turn_particles = $soft_trail_particles
@onready var hard_turn_particles = $hard_trail_particles

@export var ACC_RATE = 0.0
@export var IDLE_MAX_SPEED = 0.0
@export var ROTATION_SPEED = 0.0
@export var SOFT_ROTATION_ANGLE = 0.0
@export var SOFT_MAX_SPEED = 0.0
@export var SOFT_TURN_SPEED = 0.0
@export var HARD_ROTATION_ANGLE = 0.0
@export var HARD_MAX_SPEED = 0.0
@export var HARD_TURN_SPEED = 0.0
@export var STOP_ROTATION_ANGLE = 0.0
@export var JUMP_HEIGHT = 0.0
@export var JUMP_DURATION = 0.0

@onready var control: Control = $"../Control"

var body_to_delete

func _ready() -> void:
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
	var distance_this_frame = (GlobalState.player_speed * delta) / 2
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
	
