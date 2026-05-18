extends CanvasItem

class_name NavigationHandler

@export var debug_mode = false

@export_flags_2d_physics var layers : int

@export var entity : PlatformerStats

var nav := AStar2D.new()

var _room : Room
var _target_room : Room

@onready var _body : CharacterBody2D = get_parent()

var cached_path

const MARGIN_OF_ERROR = 1


func is_bidirectional(_low_point:Vector2, _high_point:Vector2) -> bool:
	# Always bidireectional by default
	return true
	
func get_next_point(start_point:Vector2, end_point:Vector2, cache = true):
	# Make sure remap isn't needed
	check_for_remap(start_point, end_point)
	if nav.get_point_count() == 0:
		return null
	
	# Approximate locations
	var start_ID = nav.get_closest_point(start_point)
	var end_ID = nav.get_closest_point(end_point)
	
	# Go to end if points cannot be found
	if start_ID == -1 or end_ID == -1:
		return start_point
	
	# Get the path (cached or new)
	var path : PackedInt64Array
	
	if cache and cached_path and start_ID == cached_path[0] and end_ID == cached_path[cached_path.size() - 1]:
		# Cached path is the same
		path = cached_path
	
	else:
		# Use ASTAR to find  new path
		path = nav.get_id_path(start_ID, end_ID)
		
		# Cache the path if needed
		if cache:
			cached_path = path
			
	if path.size() == 0:
		return end_point
			
	var first_point = nav.get_point_position(path[0])
	var second_point 
	
	# Go to end if path is too short
	if path.size() < 2:
		second_point = end_point
	else:
		second_point = nav.get_point_position(path[1])
	
	# Skip to second point if too close to margin of error
	if (start_point - first_point).length() <= MARGIN_OF_ERROR:
		return second_point
		
	# Skip point in some conditions
	if _is_skippable(first_point, second_point, start_point):
		return second_point
	else:
		return first_point

func _draw():
	if debug_mode:
		for i in nav.get_point_ids():
			for i2 in nav.get_point_connections(i):
				if nav.are_points_connected(i, i2, false):
					var point1 = nav.get_point_position(i)
					var point2 =  nav.get_point_position(i2)
					
					if point1.y <= point2.y:
						if nav.are_points_connected(i2, i, false):
							var p = Color.WEB_PURPLE
							p.a = .5
							draw_line(point1, point2, p, 16, true)
						else:
							var p = Color.ORANGE
							p.a = .5
							draw_line(point1, point2, p, 15, true)
						
					draw_string(ThemeDB.fallback_font, (point1 + point2)/2 + Vector2.LEFT * 20, 
					str(round(abs(rad_to_deg((point2 - point1).angle())))))

func check_for_remap(start_point : Vector2, end_point : Vector2):
	# Make sure map is avaliable
	if nav.get_point_count() == 0 or _room == null or _target_room == null or !_room.contains_point(start_point) or !_target_room.contains_point(end_point):
		_remap_for_room(start_point, end_point)
		
func _remap_for_room(start_point : Vector2, end_point : Vector2):
	var manager = RoomManager.current
	
	_room = manager.get_current_room(start_point)
	
	_target_room = manager.get_current_room(end_point)
	
	# NPC is outside; something is very wrong
	if _room == null:
		return
		
	# target room is unfound or redundant; ignore it
	if _target_room == null or _target_room == _room:
		_map_points(_room.nav_points)
		return
	
	var room_path = manager.nav.get_id_path(manager.coords_to_id(_room.coords), manager.coords_to_id(_target_room.coords))
		
	var points_list : Array[Vector2] = []
	
	for room_id in room_path:
		points_list.append_array(manager.get_room(manager.id_to_coords(room_id)).nav_points)
		
	_map_points(points_list)
	
func _map_points(points:Array[Vector2]):
	# Remove old map
	nav.clear()
	
	# Add all new points
	for i in range(len(points)):
		nav.add_point(i, points[i])
		
	# Get the world:
	var space_state = _body.get_world_2d().direct_space_state
	
	# Set up connections
	for i in range(len(points)):
		for i2 in range(i + 1, len(points)):
			
			# Skip if invalid
			if !_is_valid(space_state, points[i], points[i2]):
				continue;
				
			# Add points, with the higher point being first
			if points[i].y < points[i2].y:
				var bidirectional = is_bidirectional(points[i2], points[i])
				nav.connect_points(i, i2, bidirectional)
			else:
				var bidirectional = is_bidirectional(points[i], points[i2])
				nav.connect_points(i2, i, bidirectional)
				
	if debug_mode:
		queue_redraw()
	
func _is_skippable(first_point:Vector2, second_point:Vector2, compare_point:Vector2) -> bool:		
	# Check if second point is actually more direct
	if (compare_point - second_point).length() < (first_point - second_point).length():
		return true
		
	return false
	
	
func _is_valid(space_state, point1:Vector2, point2:Vector2) -> bool:
	var query = PhysicsRayQueryParameters2D.create(point1, point2,
		layers)
	var result = space_state.intersect_ray(query)
	
	# Invalid if they do not have a path
	if !result.is_empty():
		return false
		
	return true
