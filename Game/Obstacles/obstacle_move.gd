extends CharacterBody3D

var player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	var direction := Vector3(0,0,1)
	velocity.z = direction.z * player.player_speed

	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body != self:		
		if body.is_in_group("Obstacle"):
			body.queue_free()
	pass # Replace with function body.
