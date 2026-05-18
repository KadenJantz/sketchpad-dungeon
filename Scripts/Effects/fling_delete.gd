extends Sprite2D

signal flung
signal delayed

@export var velocity = 20.0
@export var delay = 1.0
@export var delete_delay = 3.0
@export var use_shields : bool
@export var requirement = 100

var _collider
var _rb : RigidBody2D

# Impossibly low value to avoid confusion
var _delete_timer := -100.0
var _timer := -100.0

const UNTOUCHABLE = 8

func _physics_process(delta):
	# Is the delay timer enabled?
	if _timer != -100:
		_timer -= delta
		
		if _timer <= 0:
			delayed.emit()
		
			_timer = -100
	
	# Is the delete time enabled?
	if _delete_timer != -100:
		_delete_timer -= delta
		
		if _delete_timer <= 0:
			_rb.queue_free()
			
			_delete_timer = -100

func fling(direction : Vector2, multiplier):
	_move_to_rigidbody()
	
	# Make direction have less angle vertically
	direction /= 2
	
	_rb.linear_velocity = direction.normalized() * multiplier * velocity
	
	# Start countdowns
	_timer = delay
	_delete_timer = delete_delay
	
	# Flung successfully
	flung.emit()
	
func fling_from_hit(direction, attacker, receptient):
	# Already flung
	if _delete_timer != -100:
		return
	
	# Wait for requirement
	var current
	
	if use_shields and "shields" in receptient:
		current = receptient.shields
		
	elif "health" in receptient:
		current = receptient.health
	
	if current > requirement:
		return
	
	var multiplier = 1
	
	# Add knockback if applicable
	if attacker.last_item:
		multiplier += attacker.last_item.knockback
		
	# Decrease verticality
	direction.y /= 5
	
	fling(direction, multiplier)
	
func _move_to_rigidbody():
	# Instantiate rigidbody and collider
	_rb = RigidBody2D.new()
	_collider = CollisionShape2D.new()
	
	# Fix scaling
	var old_scale = global_scale
	_rb.position = global_position
	position = Vector2.ZERO
	
	# Set up heirarchy
	get_tree().root.add_child(_rb)
	get_parent().remove_child(self)
	_rb.add_child(self)
	_rb.add_child(_collider)
	
	# Finish scale fix
	global_scale = old_scale
	
	# Configure collider size
	_collider.shape = CapsuleShape2D.new()
	_collider.shape.radius = self.texture.get_width()/2.0 * abs(global_scale.x)
	_collider.shape.height = self.texture.get_height() * abs(global_scale.y)
	
	# Configure collider rotation
	_collider.rotation = rotation
	
	# Make untouchable
	_rb.collision_layer = UNTOUCHABLE
	_rb.collision_mask = 1
