extends Resource

class_name DamageText

@export var text:PackedScene
@export var time = 1.0
@export var speed = 50
@export var follow_speed = 2

var objects : Array[Node]
var targets : Array[Node]
var offsets: Array[Vector2]
var times: Array[float]

const _CRIT_COLOR = Color.WHITE

func physics_process(caller, _item):
	for i in range(len(times)):
		# Get old scale while time hasn't updated
		var old_scale = objects[i].scale * time/times[i]
		
		# Advance time
		var delta = caller.get_physics_process_delta_time()
		times[i] -= delta
		
		if times[i] <= 0:
			# It's over, delete and remove
			var object = objects[i]
			
			objects.remove_at(i)
			targets.remove_at(i)
			offsets.remove_at(i)
			times.remove_at(i)
			
			object.queue_free()
			
			return
			
		# Move according to speed
		offsets[i] += speed * Vector2.UP * delta
		
		# Scale according to time remaining
		objects[i].scale = old_scale * times[i]/time
		
		# Lerp object to new position
		if targets[i] != null and is_instance_valid(targets[i]):
			var new_position = offsets[i] + targets[i].global_position
			objects[i].position = lerp(objects[i].position, new_position, delta * follow_speed)
	

func on_hit(caller, item):
	# Spawn text object
	var text_object = text.instantiate()
	caller.last_hit_target.get_tree().root.add_child(text_object)
	
	# Set it up
	var damage = item.damage
		
	if caller.is_last_hit_a_crit():
		damage = item.get_critical()
		
		var outline = text.instantiate()
		outline.add_theme_constant_override("outline_size", 120)
		outline.show_behind_parent = true
		text_object.add_child(outline)
		outline.position = Vector2.ZERO
		outline.scale = Vector2.ONE
		
		text_object.add_theme_color_override("font_outline_color", _CRIT_COLOR)
		
	if "color" in item and item.color != null:
		text_object.add_theme_color_override("font_color", item.color)
		
	text_object.position += caller.last_hit_pos
	text_object.text = str(int(damage))
	
	# Add to arrays
	objects.append(text_object)
	targets.append(caller.last_hit_target)
	offsets.append(text_object.position - caller.last_hit_target.global_position)
	times.append(time)
	
	pass
