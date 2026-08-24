class_name AxeAbility
extends AbilityController

## Button-triggered axe swing (test/timed-abilities branch).
## Destroys any "Tree" group body currently inside the player's
## "AxeSwingArea" node (an Area3D sibling of this node, child of Player -
## see Notes/TEST-TIMED-ABILITIES.md for the node Josh adds in-editor).
## The area's size is kept in sync with get_area_scale() whenever a stack
## is added, so it's already correctly sized by the time the button fires.
##
## Heat reward per tree (freeze-timer seconds, see control.gd's
## add_freeze_time): 1/8 of what a coffee gives. Saw-cut trees give no
## heat - only the axe (and hammer, for boulders/snow barriers) do.

const _TREE_HEAT := 0.625

func _ready() -> void:
	super._ready()
	_sync_area_scale()

func add_stack() -> void:
	super.add_stack()
	_sync_area_scale()

var _player_ref: CharacterBody3D = null
var _trees_cut_this_swing: int = 0

func _perform_effect(player: CharacterBody3D, _area_scale: float) -> void:
	_player_ref = player
	_trees_cut_this_swing = 0
	var area := player.get_node_or_null("AxeSwingArea") as Area3D
	if area == null:
		push_warning("AxeAbility: no 'AxeSwingArea' child on Player - add it in Player.tscn.")
		return
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Tree"):
			_cut_tree(body)
	# Timed-abilities test - also catch trees the player skis into DURING the
	# swing animation, not just whatever was already in range at the instant
	# the button was pressed. See Notes/TEST-TIMED-ABILITIES.md.
	_watch_area_for_duration(area, "Tree", stats.swing_duration, _cut_tree)
	# Combo system - report the full swing's tally to ComboController once
	# the hit window closes, so trees caught mid-swing above still count.
	get_tree().create_timer(stats.swing_duration).timeout.connect(_report_swing_to_combo)

func _report_swing_to_combo() -> void:
	if _player_ref == null:
		return
	# Combo system fix - if the player got hit partway through this swing,
	# on_hurt() already ended whatever combo was active. This report timer
	# runs independently of that hit, so without this check it could
	# resurrect a brand new combo right on top of the one that just ended.
	# Vuln lasts 1.5s vs. this 0.5s swing window, so checking state here
	# reliably catches "hit during this swing" and just drops the tally.
	if _player_ref.player_state_manager.current_state_name == "Vuln":
		_trees_cut_this_swing = 0
		return
	var combo := _player_ref.get_node_or_null("ComboController") as ComboController
	if combo:
		combo.report_tree_swing(_trees_cut_this_swing)
	_trees_cut_this_swing = 0

func _cut_tree(tree: Node3D) -> void:
	var shape := tree.get_node_or_null("CollisionShape3D")
	if shape:
		shape.set_deferred("disabled", true)
	EventBus.tree_cut.emit(tree.global_position)
	var tween := tree.create_tween().set_parallel(true)
	tween.tween_property(tree, "scale", Vector3.ONE * 0.001, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(tree.queue_free)
	_trees_cut_this_swing += 1
	if _player_ref and "control" in _player_ref and _player_ref.control:
		_player_ref.control.add_freeze_time(_TREE_HEAT)

func _sync_area_scale() -> void:
	var player := get_parent()
	if player == null:
		return
	var area := player.get_node_or_null("AxeSwingArea") as Area3D
	if area:
		var scale_value := get_area_scale()
		area.scale = Vector3.ONE * scale_value
		# Timed-abilities test - AxeSwingArea scales uniformly on X/Y/Z as
		# stacks grow, which would also stretch RangeRing's small ground
		# offset upward. Counteract on the ring's own local Y so it stays
		# flush on the snow and keeps a constant ring thickness at any stack
		# count. See Notes/TEST-TIMED-ABILITIES.md.
		var ring := area.get_node_or_null("RangeRing") as Node3D
		if ring and scale_value != 0.0:
			ring.scale.y = 1.0 / scale_value
			ring.position.y = 0.05 / scale_value
