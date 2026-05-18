extends Node

class_name RoomManager

static var current : RoomManager

@export var room_scale = Vector2(250, 250) ## Maximum size of rooms in pixels
@export var room_count = Vector2(10, 3) ## Count of rooms on the room grid
@export var start_level = 0

@export var allowed_enemies : Array[EnemyStats]
@export var difficulty_rating : int = 100

# Allows for navigation of the rooms by AI
var nav := AStar2D.new()

var rooms : Array[Array]

func _init():
	current = self
	
func on_generated():
	# Get room list
	var room_list : Array[Room] = []
	for column in rooms:
		room_list.append_array(column)
	
	var cost := difficulty_rating
	
	# Distrubute cost among rooms randomly
	room_list.shuffle()
	for room in range(room_list.size() - 1, -1, -1):
		# If all has been used, no need to go on
		if cost == 0:
			break
		
		var allocated_cost : int = cost
			
		if room > 0:
			allocated_cost = roundi((cost * randf_range(.5, 2))/(room+1))
		
		cost -= room_list[room].spawn_enemies(allocated_cost, allowed_enemies)
	
## Deletes any existing rooms and fills the array with null
func clear():
	# Delete any existing rooms
	for room_list in rooms:
		for room in room_list:
			if room != null:
				room.queue_free()
				
		room_list.clear()
		
	rooms.clear()
	nav.clear()
	
	# Fill in Array with null
	for i in range(room_count.x):
		var room_list : Array[Room] = []
		
		room_list.resize(room_count.y)
		
		rooms.append(room_list)

func get_current_room(point:Vector2):
	for roomsx in rooms:
		for room in roomsx:
			if room.contains_point(point):
				return room
			
	return null

func get_room(coords : Vector2) -> Room:
	if coords.x < 0 or coords.y < 0 or rooms.size() <= coords.x or rooms[coords.x].size() <= coords.y:
		return null
	return rooms[coords.x][coords.y]

func set_room(coords : Vector2, size : Vector2, room : Room) -> void:
	# Keep track of base coords
	room.coords = coords
	
	# Using size from stats, apply 
	for x in range(size.x):
		for y in range(size.y):
			rooms[coords.x + x][coords.y + y] = room
			
	# Also add to nav map (calculate id based on coords)
	nav.add_point(coords_to_id(coords), coords)
			
## Toggles the openings on the indicated rooms
func set_openings(pos : Vector2i, room : Room, open : bool = true) -> bool:
	var stats := room.stats
	var room_pos = pos
	
	# A room is required to generate an opening
	if room.coords.x + pos.x < 0 or room.coords.y + pos.y < 0 or room.coords.x + pos.x >= room_count.x or room.coords.y + pos.y >= room_count.y or rooms[room.coords.x + pos.x][room.coords.y + pos.y] == null:
		return false
	
	# Find position of origin of door
	if pos.x == -1:
		room_pos.x += 1
	elif pos.y == -1:
		room_pos.y += 1
	elif pos.x >= stats.unit_size.x:
		room_pos.x -= 1
	elif pos.y >= stats.unit_size.y:
		room_pos.y -= 1
	
	# Out of bounds for edge
	else:
		return false
	
	# The room this opening leads to
	var other_room : Room = rooms[room.coords.x + pos.x][room.coords.y + pos.y]
	
	var other_pos : Vector2 = room.coords + room_pos - other_room.coords
	
	# Toggle the other side opening
	if !other_room.set_open(other_pos, open):
		# If impossible, give up
		return false
	
	# Toggle the opening
	var success = room.set_open(pos, open)
		
	# Add to nav map on success
	if success:
		nav.connect_points(coords_to_id(room.coords), coords_to_id(other_room.coords), true)
	
	return success

## Finds the location of the first room in a direction. The increment should be at least a magnitude of 1
func raycast_rooms(start : Vector2, increment : Vector2) -> Vector2i:
	while true:
		# Increment from start
		start += increment
		
		# Get rounded point
		var room_pos = round(start)
		
		if get_room(room_pos) != null:
			return room_pos
			
		if is_coord_out_of_bounds(room_pos):
			return room_pos
			
	return start
		
func is_coord_out_of_bounds(coords : Vector2):
	if coords.x < 0 or coords.y < 0:
		return true
		
	elif coords.x >= room_count.x or coords.y >= room_count.y:
		return true
		
	return false

func coords_to_id(room_coords : Vector2) -> int:
	return int(room_coords.x * 100 + room_coords.y)

func id_to_coords(room_id : int) -> Vector2:
	return Vector2(room_id/100, room_id % 100)
