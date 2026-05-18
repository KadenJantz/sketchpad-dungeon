extends EnemyStats

class_name PlatformerStats

@export_group("Movement")
@export var jump_height = 140
@export_range(0, 90) var min_jump_angle: float = 45.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func jump_speed() -> float:
	return -sqrt(2 * _gravity * jump_height)
