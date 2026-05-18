extends Resource

class_name ItemAnim

@export var times: Array[float]
@export var positions: Array[Vector2]
@export var rotations: Array[float]

func length():
	return len(positions)

func get_position(step:int, direction:float):
	# Get the position for current step
	var position = positions[step]
	
	if PI/2 < abs(direction):
		# Mirror it if it is in opposite direction
		#position.x *= -1
		
		# Mrror the direction
		direction = PI - direction
	
	# Reverse mirror if player is flipped
	#if mirrored:
		#position.x *= -1
	
	return position.rotated(direction)

func get_rotation(step:int, direction:float):
	# Get the position for current step
	var rotation = rotations[step]
	
	if PI/2 < abs(direction):
		# Mrror the direction
		direction = PI - direction
		# Mirror the rotation
		#rotation = 180 - rotation
		
	#if mirrored:
		# Mirror the rotation again
		#rotation = 180 - rotation
	
	return rotation + rad_to_deg(direction)

func get_time(step:int):
	if step < len(times):
		return times[step]
	else:
		return 0
