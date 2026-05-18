extends Node
## Provides global useful functions
##
## These functions can be used anywhere

class_name Utility

## Finds the minimum difference between angles without allowing them to go over PI.
static func angle_diff(angle1: float, angle2: float) -> float:
	var difference = abs(angle1 - angle2)
	
	if (difference > PI):
		difference = PI * 2 - difference
		
	return difference

## Takes the transform info of two rects and checks if they cover the same area.
static func do_rects_overlap_transform(pos1 : Vector2, pos2 : Vector2, size1 : Vector2, size2 : Vector2, angle1 = 0.0, angle2 = 0.0) -> bool:
	# Get 1st rect points
	var rotated_size1 = (size1/2).rotated(angle1)
	var rect1 : Array[Vector2] = [pos1 - rotated_size1, pos1 + rotated_size1]
	# Mirror size
	rotated_size1.x *= -1
	rect1.append(pos1 - rotated_size1)
	rect1.append(pos1 + rotated_size1)
	
	# Get 2nd rect points
	var rotated_size2 = (size2/2).rotated(angle2)
	var rect2 : Array[Vector2] = [pos2 - rotated_size2, pos2 + rotated_size2]
	# Mirror size
	rotated_size2.x *= -1
	rect2.append(pos2 - rotated_size2)
	rect2.append(pos2 + rotated_size2)
	
	return do_rects_overlap(rect1, rect2)
	
## Takes the points of two rects and checks if they cover the same area. Check reverse should almost always be true.
static func do_rects_overlap(rect1 : Array[Vector2], rect2 : Array[Vector2], check_reverse := true) -> bool:
	# Only checks two of the four lines for now, but may need all four if testing fails
	for i in range(1, rect1.size() - 1):
		# negative = left, 0-1 = inside, 2 = right
		var last_percent = 0
		
		# Info for this side
		var corner1 := rect1[i]
		var corner2 := rect1[(i + 1) % 4]
		var direction := (corner1 - corner2).normalized()
		var distance := corner1.distance_to(corner2)
		
		# Find dot product to determine 
		for point in rect2:
			var dot_percent = direction.dot(point - corner1)/distance
			
			# Check if inside or on opposite side from last point then it is an intersection
			if (dot_percent >= -1 and dot_percent <= 0) or (last_percent != 0 and sign(last_percent) != sign(dot_percent)):
				# This is a intersection, so go on to next side
				last_percent = 0
				break
				
			last_percent = dot_percent
			
		if last_percent != 0:
			# Overlap is impossble, so return false
			return false
			
	# Reaching this point means an overlap is still possible. Check other rect's sides if needed
	if check_reverse:
		return do_rects_overlap(rect2, rect1, false)
		
	return true

## Returns where a point would be if it fell on the same line as two other points. The result may be outside the other two points.
static func project_point_on_line(line_start : Vector2, line_end : Vector2, point : Vector2) -> Vector2:
	var line_direction := (line_start - line_end).normalized()
	var vector_to_object := point - line_start
	var distance := line_direction.dot(vector_to_object)

	var closest_position := line_start + distance * line_direction

	return closest_position

static func find_child_node(parent : Node, type):
	for child in parent.get_children(false):
		if is_instance_of(child, type):
			return child
			
	return null

# Behavior: Checks top level, then descends into 1st child's children. All of 1st child's descendents are searched before moving on to 2nd child
static func find_child_node_recursive(parent : Node, type):
	# Try top level first
	var candidate = find_child_node(parent, type)
	
	if candidate != null:
		return candidate
		
	# Move to lower levels
	for child in parent.get_children(false):
		# Go through all of child's descendants
		if child.get_child_count() > 0:
			candidate = find_child_node_recursive(child, type)
			
		if candidate != null:
			return candidate
			
	return null

static func path_get(start : Object, path : String):
	if start == null:
		return null
		
	# Check if path is multilevel
	if ('/' in path):
		var cutoff := path.find('/')
		var next_start = start.get(path.substr(0, cutoff))
		if next_start != null and next_start is Object:
			# Call rest of path recursively
			path_get(next_start, path.substr(cutoff + 1))
			
		# Failed
		else:
			return null
		
	# Reached the end; send back up
	return start.get(path)
