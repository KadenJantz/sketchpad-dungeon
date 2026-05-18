extends Resource

class_name RoomStats

@export_file("*.tscn") var room : String
@export var unit_size : Vector2i
@export var openings : Array[Vector2i]
 
@export var banned_enemies : Array[EnemyStats]
