extends StaticBody3D

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	var offset = (player.player_speed * delta) * 0.09
	mesh_instance_3d.get_active_material(0).uv1_offset.z -= offset
