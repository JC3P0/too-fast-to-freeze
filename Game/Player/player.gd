extends CharacterBody3D

## Input mode toggle — swap between the existing state-machine turns and the
## new directional drag system. Switch in the Inspector; no code changes needed.
enum InputMode { STATE_MACHINE, DIRECTIONAL }
@export var input_mode: InputMode = InputMode.STATE_MACHINE

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
## Unified movement state — set each frame by the active InputStrategy.
## StateMachineStrategy mirrors player_speed with direction straight ahead.
## DirectionalStrategy sets these from drag/angle input.
## obstacle_move.gd always reads from here regardless of which strategy is active.
var player_direction: Vector3 = Vector3(0, 0, 1)
var player_current_speed: float = 0.0

var body_to_delete
var _input_strategy: InputStrategy

func _ready() -> void:
	add_to_group("Player")
	player_state_manager.initialize(self)
	player_state_manager.player_helper.init_particles(self)
	player_state_manager.set_state("Idle")
	_setup_input_strategy()

func _setup_input_strategy() -> void:
	match input_mode:
		InputMode.STATE_MACHINE:
			_input_strategy = StateMachineStrategy.new()
			player_state_manager.set_physics_process(true)
		InputMode.DIRECTIONAL:
			_input_strategy = DirectionalStrategy.new()
			player_state_manager.set_physics_process(false)
	add_child(_input_strategy)

func _input(event: InputEvent) -> void:
	_input_strategy.handle_input_event(self, event)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	_input_strategy.process_input(self, delta)
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
