extends Node2D

class_name Room

@export var stats : RoomStats

@export var nav_points : Array[Vector2]

var spawn_points : Array[SpawnPoint]

var openings : Array[Vector2i]

var color_ignore_areas : Array[RoomColorIgnorer]

var coords : Vector2i

var accessible : bool = false

var revealed := false

var _cover : Sprite2D

func _ready():
	var room_scale = RoomManager.current.room_scale
	
	_cover = load("res://Scenes/cover.tscn").instantiate()
	
	add_child(_cover)
	
	_cover.texture.width = room_scale.x * stats.unit_size.x
	_cover.texture.height = room_scale.y * stats.unit_size.y
	
	_cover.position.x = _cover.texture.width/2
	_cover.position.y = -_cover.texture.height/2

# Used to check if an object is in this room
func contains_point(point:Vector2) -> bool:
	# Too low
	if point.x < global_position.x or point.y > global_position.y:
		return false
	
	var pixel_size = Vector2(stats.unit_size) * RoomManager.current.room_scale
	
	# Too high
	if point.x >= global_position.x + pixel_size.x or point.y <= global_position.y - pixel_size.y:
		return false
		
	return true

func set_open(pos : Vector2, open : bool = true) -> bool:
	var coord_name = str(int(pos.x)) + '_' + str(int(pos.y))
	
	var success := false
	
	# Toggle open and closed versions of opening
	for child in get_children():
		if child.name.begins_with(coord_name):
			if child.is_in_group("Open"):
				# Successfully changed?
				if child.visible != open:
					success = true
				
				child.visible = open
				child.set_process_mode(PROCESS_MODE_INHERIT)
				
			elif child.is_in_group("Closed"):
				child.visible = !open
				child.set_process_mode(PROCESS_MODE_DISABLED)
				
	# Record change if there was a change
	if success:
		if open:
			openings.push_back(Vector2i(pos))
		else:
			openings.erase(Vector2i(pos))
				
	return success

func is_open(pos : Vector2) -> bool:
	return pos in openings

func mark_accessible(accessible_levels : Array[bool]) -> void:
	# No repeats
	if accessible:
		return
		
	accessible = true
	
	# All openings, open or closed
	for pos : Vector2i in stats.openings:
		# Right facing openings are inherently accessible
		if pos.x == stats.unit_size.x:
			accessible_levels[pos.y + coords.y] = true
	
	# Only open openings
	for pos : Vector2i in openings:
		# Vertical openings have the potential to make other rooms accessible
		if pos.y < 0 or pos.y == stats.unit_size.y:
			var other_room = RoomManager.current.get_room(pos + coords)
			if other_room != null:
				other_room.mark_accessible(accessible_levels)

func spawn_enemies(cost : int, allowed_enemies : Array[EnemyStats]) -> int:
	var budget := cost
	
	# Avoid banned enemies
	if stats.banned_enemies.size() > 0:
		allowed_enemies = allowed_enemies.duplicate()
		
		for enemy in stats.banned_enemies:
			allowed_enemies.erase(enemy)
			
	# Distrubute cost among spawn points randomly
	spawn_points.shuffle()
	for point in range(spawn_points.size() - 1, -1, -1):
		# If all has been used, no need to go on
		if budget == 0:
			break
		
		var allocated_budget := budget
			
		if point > 0:
			allocated_budget = roundi((budget * randf_range(.5, 2))/(point+1))
		
		budget -= spawn_points[point].choose_spawn(allocated_budget, allowed_enemies)
		
	return cost - budget


func _on_player_entered() -> void:
	# Reveal if not yet revealed
	if !revealed:
		revealed = true
		_reveal_room(Vector2.ZERO, 0)
		
	var manager := RoomManager.current
	var adjacent_rooms = []
	
	# Get all adjacent rooms
	for opening in openings:
		var other_room := manager.get_room(coords + opening)
		
		if not other_room in adjacent_rooms:
			adjacent_rooms.push_back(other_room)
			
			var other_opening = opening
			
			# Find position of origin of door
			if opening.x == -1:
				other_opening.x += 1
			elif opening.y == -1:
				other_opening.y += 1
			elif opening.x >= stats.unit_size.x:
				other_opening.x -= 1
			elif opening.y >= stats.unit_size.y:
				other_opening.y -= 1
			
			# Notify the adjacent room
			other_room._on_player_adjacent(coords + other_opening - other_room.coords)
		
	
func _on_player_adjacent(opening : Vector2) -> void:
	# Reveal when adjacent
	if !revealed:
		revealed = true
		_reveal_room(opening)
		
func _reveal_room(start : Vector2, speed : float = 1):
	for point in spawn_points:
		point.trigger_spawn()
		
	var centered_start = (start + Vector2.ONE)/Vector2(stats.unit_size + Vector2i.ONE)
	
	centered_start.y = 1 - centered_start.y
		
	_cover.begin(centered_start, stats.unit_size.length() * speed)
