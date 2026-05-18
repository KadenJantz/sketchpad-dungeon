extends Area2D

class_name Projectile

signal object_hit(object : CollisionObject2D)
signal targetable_hit(targetable : CollisionObject2D)

@export var source : Node2D
@export var dyn_target : Node2D
@export var target : Vector2:
	set (value):
		target = value
		_direction = (target - global_position).normalized()
@export var speed := 100.0
@export var auto_rotate_speed := 1.0

@export var knockback : float
@export var damage : int
@export var skip_shield = false
@export var statuses : Array[PackedScene]

var _start_rot : float
var _direction : Vector2

func _init() -> void:
	area_entered.connect(area_enter)
	body_entered.connect(body_enter)
	
func _ready() -> void:
	_start_rot = global_rotation
	if dyn_target != null:
		target = dyn_target.global_position
	refresh_rotation()

func _physics_process(delta: float) -> void:
	# Adjust towards dynamic target if one exists
	if dyn_target != null:
		target = dyn_target.global_position
		
	# Source must always be set
	if source == null:
		source = self
	
	# Rotate towards target if not already
	if auto_rotate_speed > 0 and global_rotation != _start_rot + _direction.angle():
		var angle_change := angle_difference(global_rotation, _start_rot + _direction.angle())
		if abs(angle_change) <= delta * auto_rotate_speed:
			# Set directly if close enough
			refresh_rotation()
		else:
			# Move towards angle at set speed
			global_rotation += delta * auto_rotate_speed * sign(angle_change)
		
	# Use rotation multiplier if auto rotating to simulate turning
	var rot_mult := 1.0
	if auto_rotate_speed > 0:
		rot_mult = maxf(0.0, 1.0 - abs(rad_to_deg(angle_difference(global_rotation, _start_rot + _direction.angle())/180)))
		
	# Move towards target
	global_position += _direction * speed * delta * rot_mult

func area_enter(_area : Area2D) -> void:
	pass
	
func body_enter(body : Node2D) -> void:
	if body is CollisionObject2D:
		if body.get_collision_layer_value(1):
			hit_object(body)
		else:
			hit_targetable(body)

func hit_object(object : CollisionObject2D) -> void:
	object_hit.emit(object)
	queue_free()
	
func hit_targetable(targetable : CollisionObject2D) -> void:
	# Apply damage and knockback
	if targetable.has_method("take_damage"):
		targetable.take_damage(damage, source, skip_shield, knockback, _direction)
		
	# Add applied objects to children
	for status in statuses:
		var spawned : Node2D = status.instantiate()
		targetable.add_child(spawned)
		
		# Mimic transform
		spawned.position = Vector2.ZERO
		spawned.rotation = 0
		spawned.skew = 0
		spawned.scale = Vector2.ONE
		
		# Transfer direction if left blank on status
		if "direction" in spawned and spawned.direction == Vector2.ZERO:
			spawned.direction = _direction
	
	targetable_hit.emit(targetable)
	queue_free()
	
func refresh_rotation() -> void:
	global_rotation = _start_rot + _direction.angle()
