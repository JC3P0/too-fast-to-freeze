class_name AbilityController
extends Node

## Strategy + Template Method base for all player abilities.
## Concrete abilities (AxeAbility, SawAbility, HammerAbility) override
## _perform_effect() only - cooldown, stacks, and HUD data all live here.
##
## Attach a concrete subclass script to a Node child of Player (e.g.
## "AxeAbility"), then assign an AbilityResource .tres to `stats` in the
## Inspector. test/timed-abilities branch - see Notes/TEST-TIMED-ABILITIES.md §4.

@export var stats: AbilityResource

## Stacks are PERMANENT - using the ability never spends one. Only add_stack()
## (called from a pickup) changes this. Capped at stats.max_stacks.
var current_stacks: int = 0
var _cooldown_remaining: float = 0.0

func _ready() -> void:
	if stats:
		current_stacks = stats.start_stacks

func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = max(0.0, _cooldown_remaining - delta)

## Call from player._input() on the mapped input_action's "pressed" event.
func try_activate(player: CharacterBody3D) -> void:
	if stats == null or _cooldown_remaining > 0.0:
		return
	# Can't use an ability while stunned - matches the old fire_saw() guard.
	if player.player_state_manager.current_state_name == "Vuln":
		return
	_perform_effect(player, get_area_scale())
	_cooldown_remaining = get_cooldown()
	EventBus.ability_fired.emit(stats.id)

func add_stack() -> void:
	if stats == null or current_stacks >= stats.max_stacks:
		return
	current_stacks += 1
	EventBus.ability_stack_changed.emit(stats.id, current_stacks)

func is_maxed() -> bool:
	return stats != null and current_stacks >= stats.max_stacks

func get_cooldown() -> float:
	if stats == null:
		return 0.0
	return max(stats.min_cooldown, stats.base_cooldown - current_stacks * stats.cooldown_decrease_per_stack)

func get_area_scale() -> float:
	if stats == null:
		return 1.0
	return min(stats.max_area_scale, stats.base_area_scale + current_stacks * stats.area_growth_per_stack)

## For the test HUD - "power" as a percentage of max stacks.
func get_power_percent() -> float:
	if stats == null or stats.max_stacks == 0:
		return 0.0
	return float(current_stacks) / float(stats.max_stacks)

## For the HUD - seconds left before this ability can fire again.
func get_cooldown_remaining() -> float:
	return _cooldown_remaining

## For the HUD - true once the cooldown has finished and the ability can fire.
func is_ready() -> bool:
	return _cooldown_remaining <= 0.0

## Template Method hook - subclasses implement the actual gameplay effect.
func _perform_effect(_player: CharacterBody3D, _area_scale: float) -> void:
	pass
