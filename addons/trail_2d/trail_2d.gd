extends Line2D

signal finished

@export_category('Trail')
@export var spawn_spot : Node2D
@export var length : = 10
@export var duration : = 0.0
@export var emitting = true
@export var global = true : set = set_global

@export_category('Movement')
@export var velocity : Vector2

@onready var parent : Node2D = get_parent()
var offset : = Vector2.ZERO
var timer : = 0.0

func _ready() -> void:
	offset = position
	top_level = global;
	
	parent.scale /= parent.global_scale

func _physics_process(delta: float) -> void:
	if emitting:
		# Handle timer
		if timer > 0:
			timer -= delta
			
		# End timer if it is applicable
		elif duration > 0:
			emitting = false
		
		# Grab position relative to what the line is relative to
		var pos = position;
		if global:
			pos = spawn_spot.global_position
			
		add_point(pos, 0)
	
	# Do not go above length of trail
	if get_point_count() > length:
		remove_point(get_point_count() - 1)
		
	# Despawn when done emitting
	if !emitting:
		if get_point_count() >= 1:
			remove_point(get_point_count() - 1)
			
		finished.emit()
		
	 # Movement
	if velocity.length() > 0 and get_point_count() > 1:
		# Move all points at velocity speed
		for i in range(1, get_point_count()):
			set_point_position(i, get_point_position(i) + (velocity * delta))
			

func set_emitting(emit:bool):
	emitting = emit
	
	# Begin timer if it is applicable
	if emit and duration > 0:
		timer = duration

func set_global(is_global:bool):
	global = is_global
	
	top_level = is_global
