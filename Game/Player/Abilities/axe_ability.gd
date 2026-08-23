class_name AxeAbility
extends AbilityController

## Button-triggered axe swing (test/timed-abilities branch).
## Destroys any "Tree" group body currently inside the player's
## "AxeSwingArea" node (an Area3D sibling of this node, child of Player -
## see Notes/TEST-TIMED-ABILITIES.md for the node Josh adds in-editor).
## The area's size is kept in sync with get_area_scale() whenever a stack
## is added, so it's already correctly sized by the time the button fires.

func _ready() -> void:
	super._ready()
	_sync_area_scale()

func add_stack() -> void:
	super.add_stack()
	_sync_area_scale()

func _perform_effect(player: CharacterBody3D, _area_scale: float) -> void:
	var area := player.get_node_or_null("AxeSwingArea") as Area3D
	if area == null:
		push_warning("AxeAbility: no 'AxeSwingArea' child on Player - add it in Player.tscn.")
		return
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Tree"):
			_cut_tree(body)

func _cut_tree(tree: Node3D) -> void:
	var shape := tree.get_node_or_null("CollisionShape3D")
	if shape:
		shape.set_deferred("disabled", true)
	EventBus.tree_cut.emit(tree.global_position)
	var tween := tree.create_tween().set_parallel(true)
	tween.tween_property(tree, "scale", Vector3.ONE * 0.001, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(tree.queue_free)

func _sync_area_scale() -> void:
	var player := get_parent()
	if player == null:
		return
	var area := player.get_node_or_null("AxeSwingArea") as Area3D
	if area:
		area.scale = Vector3.ONE * get_area_scale()
