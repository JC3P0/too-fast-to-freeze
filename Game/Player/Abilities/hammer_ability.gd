class_name HammerAbility
extends AbilityController

## Button-triggered hammer smash (test/timed-abilities branch).
## Destroys any "Boulder" group body currently inside the player's
## "HammerSwingArea" node (an Area3D sibling of this node, child of Player).
## Boulders ONLY - confirmed, not trees, not snow barriers.
## Area size kept in sync with get_area_scale() whenever a stack is added.

func _ready() -> void:
	super._ready()
	_sync_area_scale()

func add_stack() -> void:
	super.add_stack()
	_sync_area_scale()

func _perform_effect(player: CharacterBody3D, _area_scale: float) -> void:
	var area := player.get_node_or_null("HammerSwingArea") as Area3D
	if area == null:
		push_warning("HammerAbility: no 'HammerSwingArea' child on Player - add it in Player.tscn.")
		return
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Boulder"):
			_smash_boulder(body)

func _smash_boulder(boulder: Node3D) -> void:
	var shape := boulder.get_node_or_null("CollisionShape3D")
	if shape:
		shape.set_deferred("disabled", true)
	var tween := boulder.create_tween().set_parallel(true)
	tween.tween_property(boulder, "scale", Vector3.ZERO, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(boulder.queue_free)

func _sync_area_scale() -> void:
	var player := get_parent()
	if player == null:
		return
	var area := player.get_node_or_null("HammerSwingArea") as Area3D
	if area:
		area.scale = Vector3.ONE * get_area_scale()
