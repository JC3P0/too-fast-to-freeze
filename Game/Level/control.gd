extends Control

@onready var speed_label: Label = $PanelContainer/VBoxContainer/SpeedContainer/SpeedCurrent
@onready var distance_label: Label = $PanelContainer/VBoxContainer/DistanceContainer/DistanceCurrent
@onready var freeze_timer = $FreezeTimer
@onready var freeze_progress_bar = $FreezeProgressBar
@onready var percentage_of_time
@onready var game_over_scene = $"../../../GameOverScreen"
@onready var axe_count_label: Label = $PanelContainer/VBoxContainer/AxeContainer/AxeCount
@onready var saw_count_label: Label = $PanelContainer/VBoxContainer/SawContainer/SawCount
@onready var saw_button: Button = $ButtonSawBlade

## Timed-abilities test (test/timed-abilities branch) - hammer HUD + cooldown
## bars on all three ability buttons. get_node_or_null so the game keeps
## working before these nodes exist in control.tscn. See
## Notes/TEST-TIMED-ABILITIES.md.
@onready var hammer_count_label := get_node_or_null("PanelContainer/VBoxContainer/HammerContainer/HammerCount") as Label
@onready var axe_button := get_node_or_null("ButtonAxe") as Button
@onready var hammer_button := get_node_or_null("ButtonHammer") as Button
@onready var axe_cooldown_bar := get_node_or_null("ButtonAxe/CooldownBar") as ProgressBar
@onready var saw_cooldown_bar := get_node_or_null("ButtonSawBlade/CooldownBar") as ProgressBar
@onready var hammer_cooldown_bar := get_node_or_null("ButtonHammer/CooldownBar") as ProgressBar

const _READY_COLOR := Color(0.5, 1.0, 0.5)
const _COOLDOWN_COLOR := Color(0.55, 0.55, 0.55)

var player: Node = null
var coffee_time = 5.0

func _ready() -> void:
	freeze_timer.connect("timeout", Callable(self, "_on_stop_freeze_timer_timeout"))
	axe_count_label.text = "0"
	EventBus.axe_picked_up.connect(_on_axe_count_changed)
	EventBus.axe_used.connect(_on_axe_count_changed)
	saw_count_label.text = "0"
	EventBus.saw_picked_up.connect(_on_saw_picked_up)
	# Timed-abilities test - saw_fired is still emitted by SawAbility itself
	# (used elsewhere), but it is NOT connected to _on_saw_fired here anymore.
	# That old handler wrote a bare number to saw_count_label, which stomped
	# the "x/10" text _refresh_all_ability_labels() sets on stack change.
	# Stacks never change on fire, so the label doesn't need updating then.
	saw_button.pressed.connect(_on_saw_button_pressed)

	# Timed-abilities test - stack/power labels driven by the new
	# ability_stack_changed signal; every ability starts with 1 stack now,
	# so the buttons are visible from the start of the run (no more
	# hide-until-first-pickup like the old saw-only button had).
	EventBus.ability_stack_changed.connect(_on_ability_stack_changed)
	if axe_button:
		axe_button.pressed.connect(_on_axe_button_pressed)
	if hammer_button:
		hammer_button.pressed.connect(_on_hammer_button_pressed)

func _process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		if player:
			_refresh_all_ability_labels()
	if not player:
		return
	speed_label.text = str(int(player.player_current_speed))
	distance_label.text = str(int(GlobalState.total_distance))
	if freeze_timer.get_time_left() > 0:
		freeze_progress_bar.value = 60 - freeze_timer.time_left

	_update_ability_button(axe_button, axe_cooldown_bar, player.axe_ability)
	_update_ability_button(saw_button, saw_cooldown_bar, player.saw_ability)
	_update_ability_button(hammer_button, hammer_cooldown_bar, player.hammer_ability)

func _on_stop_freeze_timer_timeout():
	game_over_scene.show_game_over()
	print("game_over!")

func add_freeze_time():
	var new_time = freeze_timer.time_left + coffee_time
	if new_time > 60:
		new_time = 60
	freeze_timer.wait_time = new_time
	freeze_timer.start()

## OLD consumable-charge axe/saw HUD handlers - left defined but dormant.
## axe_picked_up/axe_used/saw_picked_up are no longer emitted anywhere
## (player.gd now calls *Ability.add_stack() instead), and _on_saw_fired is
## no longer connected to anything (see note above _on_saw_button_pressed's
## connect call in _ready()). Superseded by _on_ability_stack_changed() below.
## Not deleted per Notes/TEST-TIMED-ABILITIES.md "Keeping the old system
## intact for now."
func _on_axe_count_changed(count: int) -> void:
	axe_count_label.text = str(count)

func _on_saw_picked_up(count: int) -> void:
	saw_count_label.text = str(count)

func _on_saw_fired(count: int) -> void:
	saw_count_label.text = str(count)

func _on_saw_button_pressed() -> void:
	if player and player.saw_ability:
		player.saw_ability.try_activate(player)

# -- Timed-abilities test - stack/power labels + cooldown buttons -----------

func _on_ability_stack_changed(_id: StringName, _stacks: int) -> void:
	_refresh_all_ability_labels()

func _refresh_all_ability_labels() -> void:
	_update_ability_label(axe_count_label, player.axe_ability)
	_update_ability_label(saw_count_label, player.saw_ability)
	_update_ability_label(hammer_count_label, player.hammer_ability)

## Shows "stacks/max" - e.g. "3/10". Matches the test HUD
## requirement in Notes/TEST-TIMED-ABILITIES.md section 1.
func _update_ability_label(label: Label, ability: AbilityController) -> void:
	if label == null or ability == null or ability.stats == null:
		return
	label.text = "%d/%d" % [ability.current_stacks, ability.stats.max_stacks]

## Grays the button out with a draining cooldown bar while on cooldown,
## turns it green once ready - same "poll every frame" technique as
## freeze_progress_bar above, just reading AbilityController instead of a Timer.
func _update_ability_button(button: Button, cooldown_bar: ProgressBar, ability: AbilityController) -> void:
	if button == null or ability == null or ability.stats == null:
		return
	if cooldown_bar:
		var total := ability.get_cooldown()
		cooldown_bar.max_value = total if total > 0.0 else 1.0
		cooldown_bar.value = ability.get_cooldown_remaining()
	button.modulate = _READY_COLOR if ability.is_ready() else _COOLDOWN_COLOR

func _on_axe_button_pressed() -> void:
	if player and player.axe_ability:
		player.axe_ability.try_activate(player)

func _on_hammer_button_pressed() -> void:
	if player and player.hammer_ability:
		player.hammer_ability.try_activate(player)
