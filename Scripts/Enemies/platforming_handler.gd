extends NavigationHandler

class_name PlatformingHandler

@export var max_distance = 264

# Get the gravity from the project settings to be synced with RigidBody nodes.
var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func is_bidirectional(point1:Vector2, point2:Vector2) -> bool:	
	# Find angle from lower to higher
	var angle = abs(rad_to_deg((point1 - point2).angle()))
	
	# Make angle positive
	if angle > 90:
		angle = 180 - angle
	
	# Bidirectional if no jumping needed
	if angle <= entity.min_jump_angle:
		return true
		
	var vertical = abs(point1.y - point2.y)
	
	# Not bidirectional if out of jump range
	if vertical >= entity.jump_height:
		return false
		
	# Find the time to reach the point
	var time = abs(point1.x - point2.x)/entity.move_speed
	
	# It will definetly make it if there is no time needed
	if time == 0:
		return true
	
	# Find the jump height after this time has past
	var height_at_time
	
	if entity.jump_height > -entity.jump_speed() * time:
		height_at_time = entity.jump_height - (time * time * _gravity/2)
	else:
		height_at_time = -entity.jump_speed() * time - (time * time * _gravity/2)
	
	# Not bidirectional if out of jump range
	if vertical >= height_at_time:
		return false
	
	return true

func _is_skippable(first_point:Vector2, second_point:Vector2, compare_point:Vector2) -> bool:
	# Skippable conditions that only apply to jumping
	if first_point.y > second_point.y and abs(PI/2 + (second_point - first_point).angle()) < deg_to_rad(90 - entity.min_jump_angle):
		return false 
	
	return super(first_point, second_point, compare_point)

func _is_valid(space_state, point1:Vector2, point2:Vector2) -> bool:
	# Far away points should not bother connecting
	if point1.distance_to(point2) > max_distance:
		return false
		
	return super(space_state, point1, point2)
