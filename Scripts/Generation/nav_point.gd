extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var room = owner
	
	while not room is Room:
		room = room.owner
	
	if can_process():
		room.nav_points.push_back(global_position)
