extends Node3D

@onready var marker_a: Marker3D = $MarkerA
@onready var marker_b: Marker3D = $MarkerB
@onready var obstacle_holder: Node3D = $ObstacleHolder

var spawn_distance_interval = 1.0
var last_spawn_distance = 0.0

const TREE_S = preload("res://Game/Obstacles/Tree/tree_s.tscn")
const TREE_M = preload("res://Game/Obstacles/Tree/tree_m.tscn")
const TREE_L = preload("res://Game/Obstacles/Tree/tree_l.tscn")

const SNOW_POOF_S = preload("res://Game/Obstacles/SnowPoofs/snow_poof_s.tscn")
const SNOW_POOF_M = preload("res://Game/Obstacles/SnowPoofs/snow_poof_m.tscn")
const SNOW_POOF_L = preload("res://Game/Obstacles/SnowPoofs/snow_poof_l.tscn")
const SNOW_BARRIER = preload("res://Game/Obstacles/SnowBarrier/snow_barrier.tscn")

const COFFEE = preload("res://Game/Obstacles/coffee.tscn")
const BOULDER = preload("res://Game/Obstacles/boulder.tscn")

func _physics_process(delta: float) -> void:
	
	check_spawn_obstacle()
	
	
func check_spawn_obstacle():	
	var distance_traveled = GlobalState.total_distance
	#print(distance_traveled)
	if distance_traveled - last_spawn_distance >= spawn_distance_interval:
		spawn_obstacle()
		last_spawn_distance = distance_traveled
		randomize()
		spawn_distance_interval = randi_range(2,6)

func spawn_obstacle():
	
	randomize()
	var number_of_trees = randi_range(3,11)
	var number_of_snowpoofs = randi_range(1,3)
	var number_of_snow_barrier = randi_range(1,100)
	var number_of_boulders = randi_range(1,100)
	var number_of_coffees = randi_range(1,100)
	
	for i in number_of_trees:		
		# get a random spawn point between Marker A and Marker B
		randomize()
		var spawn_point = randf_range(marker_a.global_position.x,marker_b.global_position.x)
		
		var type_of_tree = randi_range(1,3)	
		if type_of_tree == 1:				
			var new_tree = TREE_S.instantiate()
			obstacle_holder.add_child(new_tree)
			new_tree.global_position.x = spawn_point
			
		if type_of_tree == 2:				
			var new_tree = TREE_M.instantiate()
			obstacle_holder.add_child(new_tree)
			new_tree.global_position.x = spawn_point
			
		if type_of_tree == 3:				
			var new_tree = TREE_L.instantiate()
			obstacle_holder.add_child(new_tree)
			new_tree.global_position.x = spawn_point
			
		
	
	for i in number_of_snowpoofs:
		# get a random spawn point between Marker A and Marker B
		randomize()
		var spawn_point = randf_range(marker_a.global_position.x,marker_b.global_position.x)
		
		# choosese the type of snowpoof to spawn
		var type_of_snowpoof = randi_range(1,3)	
		if type_of_snowpoof == 1:				
			var new_poof = SNOW_POOF_S.instantiate()
			obstacle_holder.add_child(new_poof)
			new_poof.global_position.x = spawn_point
			
		if type_of_snowpoof == 2:				
			var new_poof = SNOW_POOF_M.instantiate()
			obstacle_holder.add_child(new_poof)
			new_poof.global_position.x = spawn_point
			
		if type_of_snowpoof == 3:				
			var new_poof = SNOW_POOF_L.instantiate()
			obstacle_holder.add_child(new_poof)
			new_poof.global_position.x = spawn_point
			
			
	if number_of_snow_barrier <= 30:		
		# get a random spawn point between Marker A and Marker B
		randomize()
		var spawn_point = randf_range(marker_a.global_position.x,marker_b.global_position.x)
		
		var new_barrier = SNOW_BARRIER.instantiate()
		obstacle_holder.add_child(new_barrier)
		new_barrier.global_position.x = spawn_point
		

	if number_of_boulders <= 30:		
		# get a random spawn point between Marker A and Marker B
		randomize()
		var spawn_point = randf_range(marker_a.global_position.x,marker_b.global_position.x)
		
		var new_boulder = BOULDER.instantiate()
		obstacle_holder.add_child(new_boulder)
		new_boulder.global_position.x = spawn_point
		
		
	if number_of_coffees <= 30:		
		# get a random spawn point between Marker A and Marker B
		randomize()
		var spawn_point = randf_range(marker_a.global_position.x,marker_b.global_position.x)
		
		var new_coffee = COFFEE.instantiate()
		obstacle_holder.add_child(new_coffee)
		new_coffee.global_position.x = spawn_point
		

func _on_despawner_body_entered(body: Node3D) -> void:
	if body.is_in_group("Obstacle"):
		body.queue_free()
	if body.is_in_group("Coffee"):
		body.queue_free()
	if body.is_in_group("SnowPuff"):
		body.queue_free()
	
