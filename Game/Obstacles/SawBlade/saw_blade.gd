extends Area3D

## Forward speed (units/sec). Blade moves in -Z toward incoming trees.
const SPEED := 30.0

## Maximum trees the blade cuts before auto-despawning.
const MAX_HITS := 15

## How fast lateral velocity decays to zero (units/sec per sec).
## Lower = wider, lazier arc. Higher = snaps to center quickly.
const ARC_RATE := 4.0

## Multiplier applied to player_direction.x on fire.
## Controls how wide the arc is at maximum player turn angle.
const LATERAL_SCALE := 20.0

## Visual spin speed in radians per second.
const SPIN_SPEED := 12.0

var _lateral_velocity: float = 0.0
var _hits: int = 0

func _ready() -> void:
	$SafetyTimer.start()

## Called by player.gd immediately after instantiation.
## lateral_input should be player_direction.x at the moment of firing.
func setup(lateral_input: float) -> void:
	_lateral_velocity = lateral_input * LATERAL_SCALE

func _process(delta: float) -> void:
	# Fly forward into incoming trees
	position.z -= SPEED * delta
	# Arc lateral drift back toward center over time
	_lateral_velocity = move_toward(_lateral_velocity, 0.0, ARC_RATE * delta)
	position.x += _lateral_velocity * delta
	# Spin the blade visually
	rotation.y += SPIN_SPEED * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Tree"):
		_cut_tree(body)
	elif body.is_in_group("Obstacle"):
		# Hit a boulder or snow barrier — blade shatters
		_destroy_blade()

func _cut_tree(tree: Node3D) -> void:
	# Disable the tree's collision so the blade passes through cleanly
	tree.get_node("CollisionShape3D").set_deferred("disabled", true)
	EventBus.tree_cut.emit(tree.global_position)
	# Same tween destruction as the axe
	var tween := tree.create_tween().set_parallel(true)
	tween.tween_property(tree, "scale", Vector3.ZERO, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(tree.queue_free)
	_hits += 1
	if _hits >= MAX_HITS:
		_destroy_blade()

func _destroy_blade() -> void:
	queue_free()

func _on_safety_timer_timeout() -> void:
	_destroy_blade()
