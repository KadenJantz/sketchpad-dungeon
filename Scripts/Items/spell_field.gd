extends Area2D

class_name SpellField

@export var affected_groups : Array[String]
@export var unaffected_groups : Array[String]
@export var exceptions : Array[Node2D]
# Time before destroyed. Infinite if 0
@export var duration : float

# Current objects and entered times in ms
var objects : Dictionary[Node2D, float]

var _init_time : int

func _ready() -> void:
	_init_time = Time.get_ticks_msec()
	
	body_entered.connect(body_enter)
	body_exited.connect(body_exit)
	
func _physics_process(_delta: float) -> void:
	# Delete when duration is up
	if duration > 0 and Time.get_ticks_msec() - _init_time >= duration * 1000.0:
		queue_free()

func body_enter(body:Node2D):
	if not is_affected(body):
		return
		
	# Add to objects, unless somehow already there
	if not body in objects.keys():
		add_object(body)
		
func body_exit(body:Node2D):
	# Get rid of it if it is in the list!
	if body in objects.keys():
		remove_object(body)

func add_object(obj : Node2D):
	objects[obj] = Time.get_ticks_msec()
	
func remove_object(obj : Node2D):
	objects.erase(obj)

func refresh() -> void:	
	# Treat objects as if they just entered
	for object in objects.keys():
		objects[object] = Time.get_ticks_msec()

func is_affected(body:Node2D) -> bool:
	# Exceptions are unaffected
	if body in exceptions:
		return false
	
	# It cannot be in an unaffected group
	for u_group in unaffected_groups:
		if body.is_in_group(u_group):
			return false
			
	# It must be in an affected group
	for a_group in affected_groups:
		if body.is_in_group(a_group):
			return true

	# Return false unless no group was required
	return affected_groups.is_empty()
