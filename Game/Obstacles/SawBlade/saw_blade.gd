extends Area3D

## Forward speed (units/sec) — your only tuning knob for blade speed.
## Raise this until it feels right. Start around 15.
const SPEED := 15.0

const MAX_HITS := 6
const ARC_RATE := 2.0
const LATERAL_SCALE := 60.0
const SPIN_SPEED := 4.0

var _lateral_velocity: float = 0.0
var _hits: int = 0
var _player: Node3D = null

func _ready() -> void:
	$SafetyTimer.start()
	_player = get_tree().get_first_node_in_group("Player")

func setup(lateral_input: float) -> void:
	_lateral_velocity = -lateral_input * LATERAL_SCALE

func _physics_process(delta: float) -> void:
	if not _player:
		return
	var spd: float = _player.player_current_speed
	var dir: Vector3 = _player.player_direction

	# Z: constant speed regardless of player — blade never slows in Vuln
	position.z -= SPEED * delta

	# X: unchanged from working version — stays locked with trees when turning
	_lateral_velocity = lerp(_lateral_velocity, 0.0, ARC_RATE * delta)
	position.x += (spd * dir.x + _lateral_velocity) * delta

	rotation.y += SPIN_SPEED * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Tree"):
		_cut_tree(body)
	elif body.is_in_group("Boulder"):
		_destroy_blade()

func _cut_tree(tree: Node3D) -> void:
	tree.get_node("CollisionShape3D").set_deferred("disabled", true)
	EventBus.tree_cut.emit(tree.global_position)
	var tween := tree.create_tween().set_parallel(true)
	tween.tween_property(tree, "scale", Vector3.ZERO, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(tree.queue_free)
	_hits += 1
	if _hits >= MAX_HITS:
		_destroy_blade()

func _destroy_blade() -> void:
	if is_queued_for_deletion():
		return
	queue_free()

func _on_safety_timer_timeout() -> void:
	_destroy_blade()
