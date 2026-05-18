extends Resource

class_name ApplyColor

@export var offset: Vector2
@export var radius: float
@export var frequency := 1
@export var consistency := 1.0

var target: Node2D

var last_pos

var overlay:ColorOverlay = null

func physics_process(caller:Node2D, item):
	if !target or (last_pos and target.position == last_pos):
		return
		
	if overlay == null or (not is_instance_valid(overlay)) or overlay.owner != caller.get_tree().current_scene:
		overlay = caller.get_tree().current_scene.get_node("ColorOverlay")
		
	overlay.set_circle(target.global_position, radius, item.color)
	
	if last_pos and frequency > 1 and (target.global_position - last_pos).length() < 100:
		var median = last_pos
		
		var interval = (target.global_position - last_pos)/frequency
		
		for i in range(frequency):
			median += interval
			
			overlay.set_circle(median, radius, item.color, consistency)
		
	last_pos = target.global_position
	
func start_use(caller, item):
	# Create target
	target = Node2D.new()
	caller.add_child(target)
	
	const ITEM_RANGE_MULT = 20
	target.position = ((Vector2.RIGHT * ITEM_RANGE_MULT * item.max_range + offset) / caller.global_scale).rotated(
		-deg_to_rad(item.held_rotation))
	
func released_use(_caller, _item):
	target.queue_free()
	target = null
	last_pos = null
