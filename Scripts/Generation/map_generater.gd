extends Node2D
## Generates a unique map using predetermined rooms
##
##

@export var rooms : Array[RoomStats] ## All rooms allowed for this page
@export var repeat_prevention_length = 10.0 ## The minimum number of rooms between two repeated rooms

var _random_buffer : Array[float] # Stores the used rooms to prevent repeats if needed

const LOOP_PREVENTION = 100 # Used to prevent an infinite loop if there aren't enough rooms of a type to prevent a repeat

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate()
	
## Clears the map if needed and generates a new one
func generate() -> void:
	# Clear map
	var manager := RoomManager.current
	manager.clear()
	
	# Ensure all areas are accessible
	var open_levels : Array[bool] = []
	open_levels.resize(manager.room_count.y)
	
	var accessible : Array[bool] = []
	accessible.resize(manager.room_count.y)
	accessible[manager.start_level] = true
	
	var column := 0
	while column < manager.room_count.x:
		var level := 0
		while level < manager.room_count.y:
			var coords = Vector2(column, level)
			
			# Skip over already generated areas
			if manager.get_room(coords) != null:
				level += 1
				continue
			
			var room := _get_random_room(coords, open_levels, accessible)
			
			var instance := load(room.room).instantiate() as Room
			get_parent().add_child.call_deferred(instance)
			instance.position = coords.reflect(Vector2.RIGHT) * manager.room_scale + position
			
			manager.set_room(coords, room.unit_size, instance)
			
			# Used to mark accessibility later
			var room_accessible := false
			
			# All levels this room touches are now closed and inaccessible unless there is an opening
			for closed in range(room.unit_size.y):
				open_levels[closed + level] = false
				accessible[closed + level] = false
			
			# Set up openings
			for pos in room.openings:
				var success := manager.set_openings(pos, instance)
				
				var y_coord := pos.y + level
					
				# If the room connects to an accessible room, mark it as accessible
				if !room_accessible and (success and manager.get_room(pos + instance.coords).accessible or column == 0 and level == manager.start_level):
					room_accessible = true
				
				# If there is a potential opening to the right, mark level as open
				if pos.x == room.unit_size.x:
					open_levels[y_coord] = true
						
			# If accessible, then go back through successful openings to mark accessibility
			if room_accessible:
				instance.mark_accessible(accessible)
					
			# Move to next room in column
			level += room.unit_size.y
		
		# Next column
		column += 1
		
	var max_x = manager.rooms.size() - 1
		
	await manager.rooms[max_x][manager.rooms[max_x].size() - 1].ready
		
	manager.on_generated()
		
	queue_free()

## Returns a random room without repeats
func _get_random_room(coords : Vector2, open_levels : Array[bool], accessible : Array[bool]) -> RoomStats:
	# Determine required openings for this room
	var required := open_levels.duplicate()
	
	# Accessible openings are not required if there is more than one
	# WARNING this means that rooms cannot have more than one left side with no opening unless this is changed
	if accessible.count(true) > 1:
		for i in range(accessible.size()):
			if accessible[i]:
				required[i] = false
	
	# Get random number
	var room_num := randi_range(0, len(rooms) - 1)
	var room := rooms[room_num]
	
	# Used to check for an infinite loop
	var loops = 0
	# Get new numbers if the current one is a repeat or not applicable
	while ((room_num in _random_buffer and loops < LOOP_PREVENTION/2) or !_is_room_applicable(coords, room) or (!_check_openings(coords, room, required)) and loops < LOOP_PREVENTION):
		room_num = randi_range(0, len(rooms) - 1)
		room = rooms[room_num]
		
		loops += 1
	
	# Update repeat prevention buffer
	_random_buffer.push_back(room_num)
	
	while _random_buffer.size() > repeat_prevention_length:
		_random_buffer.remove_at(0)
	
	
	return room

# Checks if a room will fit in the given coords on the grid
func _is_room_applicable(coords : Vector2, room : RoomStats) -> bool:
	# Too far to the right
	if room.unit_size.x + coords.x > RoomManager.current.room_count.x:
		return false
		
	# Not enough space upward
	if room.unit_size.y > RoomManager.current.raycast_rooms(coords, Vector2.DOWN).y - coords.y:
		return false
		
	return true

func _check_openings(coords : Vector2, room: RoomStats, required : Array[bool]) -> bool:
	var unfulfilled = required.duplicate()
	
	# Do not need to fulfill levels not covered or adjacent
	for level in range(unfulfilled.size()):
		if level < coords.y - 1 or level > coords.y + room.unit_size.y:
			unfulfilled[level] = false
	
	# Check for openings to fulfill requirements
	for open in room.openings:
		# Ignore right facing openings
		if open.x >= room.unit_size.x:
			continue
		
		var y_value := coords.y + open.y
		
		# Out of bounds
		if y_value < 0 or y_value > coords.y + room.unit_size.y or y_value >= unfulfilled.size():
			continue
		
		if unfulfilled[y_value]:
			unfulfilled[y_value] = false
			
	# Are they all fulfilled?
	return unfulfilled.count(true) == 0
