extends Area3D

## Forward speed (units/sec) relative to the player/camera.
## The blade compensates for world scroll so this is what you actually see.
const SPEED := 5.0

## Maximum trees the blade cuts before auto-despawning.
const MAX_HITS := 6

## Exponential arc decay factor (0–1 per frame via lerp).
## Higher = snaps to straight faster. 5.0 = ~92% gone in 0.5s. 3.0 = ~78% gone in 0.5s.
const ARC_RATE := 2.0

## Multiplier applied to player_direction.x on fire.
## Controls how wide the arc is at maximum player turn angle.
const LATERAL_SCALE := 60.0

## Visual spin speed in radians per second.
const SPIN_SPEED := 4.0

var _lateral_velocity: float = 0.0
var _hits: int = 0
var _player: Node3D = null

func _ready() -> void:
	$SafetyTimer.start()
	_player = get_tree().get_first_node_in_group("Player")

## Called by player.gd immediately after add_child.
## lateral_input should be player_direction.x at the moment of firing.
func setup(lateral_input: float) -> void:
	# Negate: player_direction.x is used to move obstacles opposite to player facing,
	# so we flip the sign to fire in the direction the player is actually looking.
	_lateral_velocity = -lateral_input * LATERAL_SCALE

func _physics_process(delta: float) -> void:
	if not _player:
		return
	var spd: float = _player.player_current_speed
	var dir: Vector3 = _player.player_direction

	# Constant forward speed — no player speed compensation in Z so the
	# blade always moves at the same pace regardless of how fast the player is going.
	position.z -= SPEED * delta

	# X: match world turning scroll so the blade stays in sync with trees
	# as the player carves, plus the decaying arc from the fire angle.
	_lateral_velocity = lerp(_lateral_velocity, 0.0, ARC_RATE * delta)
	position.x += (spd * dir.x + _lateral_velocity) * delta

	# Spin the blade visually
	rotation.y += SPIN_SPEED * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Tree"):
		_cut_tree(body)
	elif body.is_in_group("Boulder"):
		# Only a boulder stops the blade — snow barriers are ignored (blade flies over)
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
