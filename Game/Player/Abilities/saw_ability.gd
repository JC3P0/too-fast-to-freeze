class_name SawAbility
extends AbilityController

## Button-triggered saw blade fire (test/timed-abilities branch).
## Unlike axe/hammer, saw doesn't need a player-side detection area - it
## spawns its own projectile scene (as it always has via fire_saw()), just
## scaled up by get_area_scale() so a maxed-out saw is visibly, comically huge.

const _SAW_BLADE_SCENE := preload("res://Game/Obstacles/SawBlade/saw_blade_projectile.tscn")

func _perform_effect(player: CharacterBody3D, area_scale: float) -> void:
	var blade := _SAW_BLADE_SCENE.instantiate()
	player.get_parent().add_child(blade)
	blade.global_position = player.global_position + Vector3(0.0, 0.0, -3.0)
	blade.scale = Vector3.ONE * area_scale
	blade.setup(player.player_direction.x)
	EventBus.saw_fired.emit(current_stacks)
