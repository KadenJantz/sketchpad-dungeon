extends State

class_name PlatformerMovement

signal jumped
signal walked
signal at_rest

@export var navigation_handler: NavigationHandler

@export var stats : PlatformerStats
@export var accel: float = 7
@export var stop_radius = 50

@onready var player : CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var _body : CharacterBody2D = owner

@onready var movement_target : Vector2 = player.global_position
@onready var react_time = randf_range(0, stats.reaction_time)

@onready var current_speed : float = stats.move_speed

# Get the gravity from the project settings to be synced with RigidBody nodes.
var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var next_point = null

const MARGIN_OF_ERROR = 1

func _supports(_node):
	# Needs the parent to be a body
	if owner is CharacterBody2D:
		return true
		
	return false

func _physics_process(delta):
	# Do not move if disabled
	if !disabled:
		_follow_path(delta)
		
	else:
		if _body.is_on_floor():
			_body.velocity.x = lerp(_body.velocity.x, 0.0, accel * delta)
			
		_body.set_collision_mask_value(6, true)
		
		at_rest.emit()
	
# Should only be called on physics process
func _follow_path(delta):
	if react_time <= 0:
		movement_target = player.global_position;
		react_time = randf_range(0, stats.reaction_time)
		
	else:
		react_time -= delta

	var jump_point = navigation_handler.get_next_point(_body.position, movement_target)

	if _body.is_on_floor() or _body.velocity.x == 0 or next_point == null:
		next_point = jump_point
	
	if jump_point == null or next_point == null:
		return

	var direction : Vector2 = (next_point - _body.global_position).normalized()
	var movement : Vector2
	
	# Connot change direction while already moving mid-air
	if _body.is_on_floor() or _body.velocity.x == 0:
		movement = direction
	else:
		movement = _body.velocity
		
	# Stop if no path to follow or too close to the player
	if (next_point - _body.global_position).length() < MARGIN_OF_ERROR or (movement_target - _body.global_position).length() < stop_radius:
		_body.velocity.x = lerp(_body.velocity.x, 0.0, accel * delta)
			
		# Face correct direction without moving
		update_direction(movement)
		
		at_rest.emit()
		return

	move_in_direction(movement, delta)
	
	# Allow for dropdown when angle is under 45 degrees downward and point is far enough away
	if abs(PI/2 - direction.angle()) < deg_to_rad(90 - stats.min_jump_angle) and (jump_point - _body.global_position).length() > MARGIN_OF_ERROR:
		_body.set_collision_mask_value(6, false)
	
	else:
		_body.set_collision_mask_value(6, true)
		
		# Jump when angle is over 45 degrees
		if abs(PI/2 + direction.angle()) < deg_to_rad(90 - stats.min_jump_angle):
			_body.velocity.x = sign(direction.x) * stats.move_speed
			
			try_jump(jump_point)
	
func move_in_direction(direction : Vector2, delta):
	# Do not move if disabled
	if disabled:
		return
		
	# Only applies if not jumping
	if _body.is_on_floor():
		current_speed = stats.move_speed
		
		if direction.x != 0:
			walked.emit()
		else:
			at_rest.emit()
			
	else:
		jumped.emit()
			
	update_direction(direction)
		
	_body.velocity.x = lerp(_body.velocity.x, sign(direction.x) * current_speed, accel * delta)
	
func update_direction(direction:Vector2):
	
	# Switch direction if neccessary
	if abs(direction.normalized().x) >= 0.5 and (_body.scale.y > 0) == (direction.x > 0):
		_body.scale.x *= -1

# Should only be called on physics process
func try_jump(target : Vector2):
	# Do not move if disabled
	if disabled:
		return
	
	# Do not jump mid-air
	if !_body.is_on_floor():
		return
	
	# All checks passed, do the jump
	_body.velocity.y = stats.jump_speed()
	
	# Adjust current speed
	var time = (-stats.jump_speed() + sqrt(pow(stats.jump_speed(), 2) + (2 * _gravity * (target.y - _body.global_position.y))))/_gravity
	
	if time * stats.move_speed > abs(target.x - _body.global_position.x):
		current_speed = abs(target.x - _body.global_position.x)/time
	
	jumped.emit()

# Should not be necessary but fixes issue
func set_disabled(disable:bool):
	super.set_disabled(disable)
