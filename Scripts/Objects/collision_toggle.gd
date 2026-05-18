extends Area2D

@export var collision : CollisionObject2D

func _ready() -> void:
	body_entered.connect(_body_entered)
	body_exited.connect(_body_exited)
	
func _body_entered(body):
	body.add_collision_exception_with(collision)
	collision.add_collision_exception_with(body)

func _body_exited(body):
	body.remove_collision_exception_with(collision)
	collision.remove_collision_exception_with(body)
