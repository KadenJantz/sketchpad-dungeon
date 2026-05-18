extends Status

class_name DragStatus

@export var direction : Vector2
@export var speed := 100.0
@export var horizontal_only : bool

var body : PhysicsBody2D

func _physics_process(delta: float) -> void:
	super(delta)
	
	if !disabled:
		# TODO disable when not alive
		if horizontal_only:
			body.move_and_collide(Vector2.RIGHT * sign(direction.x) * speed * delta)
		else:
			body.move_and_collide(direction.normalized() * speed * delta)

func begin() -> void:
	# Check that this is attached to an applicable object
	if body == null:
		if get_parent() is PhysicsBody2D:
			body = get_parent()
		else:
			# Failed. Disable and give up
			disabled = true

func on_enable() -> void:
	# Enable floating if available
	# TODO: Switch this to a system that can handle multiple sources of floating: use an int count
	if "floating" in body:
		body.floating = true
		
	# Reset velocity if it exists
	if "velocity" in body:
		body.velocity = Vector2.ZERO
	
func on_disable() -> void:
	# Disable floating if available
	if "floating" in body:
		body.floating = false
