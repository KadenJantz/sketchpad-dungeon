extends Node2D

class_name RoomColorIgnorer

var size : Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var room = owner
	
	while not room is Room:
		room = room.owner
	
	if can_process():
		room.color_ignore_areas.push_back(self)
