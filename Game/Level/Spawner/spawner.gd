extends Node3D

@onready var marker_a: Marker3D = $MarkerA
@onready var marker_b: Marker3D = $MarkerB
@onready var obstacle_holder: Node3D = $ObstacleHolder

var spawn_distance_interval := 1.0
var last_spawn_distance := 0.0

var _factory := ObstacleFactory.new()


func _ready() -> void:
	add_child(_factory)


func _physics_process(_delta: float) -> void:
	check_spawn_obstacle()


func check_spawn_obstacle() -> void:
	var distance_traveled: float = GlobalState.total_distance
	if distance_traveled - last_spawn_distance >= spawn_distance_interval:
		spawn_obstacle()
		last_spawn_distance = distance_traveled
		randomize()
		spawn_distance_interval = randi_range(2, 6)


func spawn_obstacle() -> void:
	randomize()
	var number_of_trees       := randi_range(3, 11)
	var number_of_snowpoofs   := randi_range(1, 3)
	var number_of_snow_barrier := randi_range(1, 100)
	var number_of_boulders    := randi_range(1, 100)
	var number_of_coffees     := randi_range(1, 100)

	var tree_types: Array[ObstacleFactory.ObstacleType] = [
		ObstacleFactory.ObstacleType.TREE_S,
		ObstacleFactory.ObstacleType.TREE_M,
		ObstacleFactory.ObstacleType.TREE_L,
	]
	for i in number_of_trees:
		randomize()
		_spawn(tree_types.pick_random(), _rand_x())

	var poof_types: Array[ObstacleFactory.ObstacleType] = [
		ObstacleFactory.ObstacleType.SNOW_POOF_S,
		ObstacleFactory.ObstacleType.SNOW_POOF_M,
		ObstacleFactory.ObstacleType.SNOW_POOF_L,
	]
	for i in number_of_snowpoofs:
		randomize()
		_spawn(poof_types.pick_random(), _rand_x())

	if number_of_snow_barrier <= 30:
		randomize()
		_spawn(ObstacleFactory.ObstacleType.SNOW_BARRIER, _rand_x())

	if number_of_boulders <= 30:
		randomize()
		_spawn(ObstacleFactory.ObstacleType.BOULDER, _rand_x())

	if number_of_coffees <= 30:
		randomize()
		_spawn(ObstacleFactory.ObstacleType.COFFEE, _rand_x())

	var number_of_axes := randi_range(1, 100)
	if number_of_axes <= 15:
		randomize()
		_spawn(ObstacleFactory.ObstacleType.AXE, _rand_x())


## Returns a random x position within the spawn lane defined by MarkerA and MarkerB.
func _rand_x() -> float:
	return randf_range(marker_a.global_position.x, marker_b.global_position.x)


## Instantiates an obstacle via the factory and adds it to the obstacle holder.
func _spawn(type: ObstacleFactory.ObstacleType, x: float) -> void:
	var obs: Node3D = _factory.create(type, Vector3(x, 0.0, 0.0))
	obstacle_holder.add_child(obs)


func _on_despawner_body_entered(body: Node3D) -> void:
	if body.is_in_group("Obstacle"):
		body.queue_free()
	if body.is_in_group("Coffee"):
		body.queue_free()
	if body.is_in_group("Axe"):
		body.queue_free()
	if body.is_in_group("SnowPuff"):
		body.queue_free()
