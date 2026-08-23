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
	# Timed-abilities test - also catch boulders the player skis into DURING
	# the swing animation, not just whatever was already in range at the
	# instant the button was pressed. See Notes/TEST-TIMED-ABILITIES.md.
	_watch_area_for_duration(area, "Boulder", stats.swing_duration, _smash_boulder)

func _smash_boulder(boulder: Node3D) -> void:
	var shape := boulder.get_node_or_null("CollisionShape3D")
	if shape:
		shape.set_deferred("disabled", true)
	var tween := boulder.create_tween().set_parallel(true)
	tween.tween_property(boulder, "scale", Vector3.ONE * 0.001, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(boulder.queue_free)

func _sync_area_scale() -> void:
	var player := get_parent()
	if player == null:
		return
	var area := player.get_node_or_null("HammerSwingArea") as Area3D
	if area:
		var scale_value := get_area_scale()
		area.scale = Vector3.ONE * scale_value
		# Timed-abilities test - HammerSwingArea scales uniformly on X/Y/Z as
		# stacks grow, which would also stretch RangeRing's small ground
		# offset upward. Counteract on the ring's own local Y so it stays
		# flush on the snow and keeps a constant ring thickness at any stack
		# count. See Notes/TEST-TIMED-ABILITIES.md.
		var ring := area.get_node_or_null("RangeRing") as Node3D
		if ring and scale_value != 0.0:
			ring.scale.y = 1.0 / scale_value
			ring.position.y = 0.05 / scale_value
