class_name DirectionalStrategy
extends InputStrategy

## Directional drag/angle control system — ported from WildJam76 player_mobile.gd.
## States: IDLE (no input) → TURNING (drag held) → RELEASED (drag released, pump window).
## Sets player.player_direction (Vector3) and player.player_current_speed each frame.
## obstacle_move.gd reads both X and Z from player.player_direction.
## Dynamic FOV is handled centrally in player.gd.

# --- Tunable exports ---
@export var max_speed: float = 20.0
@export var min_speed: float = 15.0
@export var acceleration: float = 5.0
@export var turn_acceleration: float = 0.05   ## Lerp step per frame; lower = lazier steering
@export var max_turn_angle: float = 60.0       ## Max yaw offset from straight ahead (degrees)
@export var pump_boost: float = 2.0            ## Speed added on a successful pump
@export var pump_speed_cap: float = 1.1        ## Pump can push speed up to this × max_speed

# --- State machine ---
enum State { IDLE, TURNING, RELEASED }
var _state: State = State.IDLE

# --- Drag tracking ---
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_current_pos: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _max_drag_distance: float = 0.0

# --- Movement ---
var _current_speed: float = 0.0
var _current_direction: Vector3 = Vector3(0, 0, 1)
var _target_direction: Vector3 = Vector3(0, 0, 1)
const _DEFAULT_DIRECTION := Vector3(0, 0, 1)

# --- Pump ---
var _previous_direction: Vector3 = Vector3(0, 0, 1)
var _pump_fired: bool = false


func _ready() -> void:
	_max_drag_distance = get_viewport().get_visible_rect().size.x / 5.0


# Called from player.gd _input() — handles mouse/touch drag events
func handle_input_event(_player: CharacterBody3D, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_start_pos = event.position
			_touch_current_pos = event.position
			_is_dragging = true
		else:
			_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		_touch_current_pos = event.position


# Called from player.gd _physics_process() each frame
func process_input(player: CharacterBody3D, delta: float) -> void:
	match _state:
		State.IDLE:
			_target_direction = _DEFAULT_DIRECTION
			_ramp_speed(delta)
			if _is_dragging:
				_state = State.TURNING

		State.TURNING:
			if _is_dragging:
				_ramp_speed(delta)
				if _touch_current_pos != _touch_start_pos:
					var drag_vector := _touch_current_pos - _touch_start_pos
					var limited_x := clamp(drag_vector.x, -_max_drag_distance, _max_drag_distance)
					var normalized_x := limited_x / _max_drag_distance
					# Negative multiplier: drag right → turn right (positive X in world)
					var turn_angle_deg := max_turn_angle * normalized_x * -1.0
					var angle_rad := deg_to_rad(turn_angle_deg)
					_target_direction = Vector3(sin(angle_rad), 0.0, cos(angle_rad)).normalized()
			else:
				# Drag released — enter pump window, reset pump flag for this release
				_pump_fired = false
				_state = State.RELEASED

		State.RELEASED:
			_target_direction = _DEFAULT_DIRECTION
			_ramp_speed(delta)

			# Pump: fires once when current_direction.x crosses zero on return to center.
			if not _pump_fired:
				var prev_sign := sign(_previous_direction.x)
				var curr_sign := sign(_current_direction.x)
				if prev_sign != 0 and curr_sign != prev_sign:
					_current_speed = min(
						_current_speed + pump_boost,
						max_speed * pump_speed_cap
					)
					_pump_fired = true

			# Return to IDLE once direction has settled back to center
			if _current_direction.is_equal_approx(_DEFAULT_DIRECTION):
				_state = State.IDLE

			# New drag → jump straight into TURNING
			if _is_dragging:
				_state = State.TURNING

	# Advance direction toward target
	_previous_direction = _current_direction
	_current_direction = _current_direction.move_toward(
		_target_direction.normalized(), turn_acceleration
	)

	# Write unified movement state to player — obstacle_move.gd and player.gd read from here
	player.player_direction = _current_direction
	player.player_current_speed = _current_speed
	# Mirror into player_speed so player.gd total_distance calc stays accurate
	player.player_speed = _current_speed


func get_strategy_name() -> String:
	return "Directional"


# --- Private helpers ---

func _ramp_speed(delta: float) -> void:
	if _current_speed < max_speed:
		_current_speed += acceleration * delta
	elif _current_speed > max_speed:
		_current_speed = max_speed
