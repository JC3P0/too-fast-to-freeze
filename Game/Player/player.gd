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

## Settings for the DirectionalStrategy control system.
## Assign directional_stats.tres in the Inspector.
@export var directional_stats: DirectionalStrategyResource

## Dynamic FOV — camera field of view lerps between min and max as speed rises.
## fov_ref_speed is the speed at which FOV reaches max (match DirectionalStrategy.max_speed).
@export var min_fov: float = 75.0
@export var max_fov: float = 88.0
@export var fov_ref_speed: float = 20.0

@onready var control: Control = $"../Control"

## Timed-abilities test (test/timed-abilities branch) - AbilityController nodes.
## get_node_or_null so the game keeps working before these children exist on
## Player.tscn. Add child Nodes named "AxeAbility"/"SawAbility"/"HammerAbility"
## with the matching scripts attached to turn each one on, plus "AxeSwingArea"/
## "HammerSwingArea" Area3D nodes for melee detection. See
## Notes/TEST-TIMED-ABILITIES.md.
@onready var axe_ability := get_node_or_null("AxeAbility") as AxeAbility
@onready var saw_ability := get_node_or_null("SawAbility") as SawAbility
@onready var hammer_ability := get_node_or_null("HammerAbility") as HammerAbility

var player_speed: float = 0.0
## Unified movement state — set each frame by the active InputStrategy.
## StateMachineStrategy mirrors player_speed with direction straight ahead.
## DirectionalStrategy sets these from drag/angle input.
## obstacle_move.gd always reads from here regardless of which strategy is active.
var player_direction: Vector3 = Vector3(0, 0, 1)
var player_current_speed: float = 0.0

var body_to_delete
var _input_strategy: InputStrategy
var _camera: Camera3D = null

const _SAW_BLADE_SCENE := preload("res://Game/Obstacles/SawBlade/saw_blade_projectile.tscn")

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
			add_child(_input_strategy)
			player_state_manager.set_physics_process(true)
		InputMode.DIRECTIONAL:
			var ds := DirectionalStrategy.new()
			ds.settings = directional_stats
			_input_strategy = ds
			add_child(_input_strategy)
			player_state_manager.set_physics_process(false)

func _input(event: InputEvent) -> void:
	_input_strategy.handle_input_event(self, event)
	# Timed-abilities test - button-triggered axe/saw/hammer via AbilityController,
	# replacing the old auto-trigger axe + key "1" saw fire below.
	# fire_axe/fire_hammer are new input actions Josh adds in Project Settings;
	# fire_saw already exists (currently bound to "1" - remap to Q/B for this test).
	# See Notes/TEST-TIMED-ABILITIES.md.
	if event.is_action_pressed("fire_axe") and axe_ability:
		axe_ability.try_activate(self)
	if event.is_action_pressed("fire_saw") and saw_ability:
		saw_ability.try_activate(self)
	if event.is_action_pressed("fire_hammer") and hammer_ability:
		hammer_ability.try_activate(self)

## OLD consumable-charge saw fire - superseded by SawAbility.try_activate()
## above (no longer called from _input()). Left in place unused per
## Notes/TEST-TIMED-ABILITIES.md §1 rather than deleted. If a HUD button
## still calls this directly, repoint it to saw_ability.try_activate(self).
func fire_saw() -> void:
	if stats.saw_count <= 0:
		return
	# Can't fire while stunned — player speed is 0 and the blade would appear stationary.
	if player_state_manager.current_state_name == "Vuln":
		return
	stats.saw_count -= 1
	EventBus.saw_fired.emit(stats.saw_count)
	var blade = _SAW_BLADE_SCENE.instantiate()
	# Add to scene tree first so global_position is valid
	get_parent().add_child(blade)
	# Spawn slightly ahead of the player at the same height
	blade.global_position = global_position + Vector3(0.0, 0.0, -3.0)
	# Pass the player's current lateral direction for the arc
	blade.setup(player_direction.x)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	_input_strategy.process_input(self, delta)
	var distance_this_frame = (player_speed * delta) / 2
	GlobalState.total_distance += distance_this_frame
	if _camera == null:
		_camera = get_node_or_null("../Camera3D")
	if _camera and fov_ref_speed > 0.0:
		_camera.fov = lerp(min_fov, max_fov, player_current_speed / fov_ref_speed)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Obstacle"):
		# --- OLD auto-trigger axe interception (charge-based) - disabled for
		# --- the timed-abilities test. Axe now fires on the fire_axe button
		# --- via AxeAbility, not reactively on tree collision. Left commented
		# --- rather than deleted per Notes/TEST-TIMED-ABILITIES.md §1
		# --- "Keeping the old system intact for now."
		# if stats.axe_count > 0 and body.is_in_group("Tree"):
		# 	stats.axe_count -= 1
		# 	body.get_node("CollisionShape3D").set_deferred("disabled", true)
		# 	EventBus.tree_cut.emit(body.global_position)
		# 	EventBus.axe_used.emit(stats.axe_count)
		# 	var tween := body.create_tween().set_parallel(true)
		# 	tween.tween_property(body, "scale", Vector3.ZERO, 0.25) \
		# 		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		# 	tween.chain().tween_callback(body.queue_free)
		player_state_manager.set_state("Vuln")
		$HurtTimer.start()
		body_to_delete = body
		EventBus.player_hit.emit(body)

	if body.is_in_group("Axe"):
		if axe_ability:
			axe_ability.add_stack()
		body.queue_free()

	if body.is_in_group("Saw"):
		if saw_ability:
			saw_ability.add_stack()
		body.queue_free()

	if body.is_in_group("Hammer"):
		if hammer_ability:
			hammer_ability.add_stack()
		body.queue_free()

	if body.is_in_group("Coffee"):
		control.add_freeze_time()
		body.queue_free()

func _on_hurt_timer_timeout() -> void:
	body_to_delete.queue_free()
