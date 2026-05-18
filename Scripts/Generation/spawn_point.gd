extends Node2D

class_name SpawnPoint

@export var tags_allowed : Array[String]

@export var selected : Resource

@export var custom_options : Array[Resource]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if can_process():
		# Default to room options
		if custom_options.is_empty():
			var room = owner
			
			while not room is Room:
				room = room.owner
			room.spawn_points.push_back(self)
			
		# Custom options replace default
		else:
			selected = custom_options.pick_random()
			
func trigger_spawn():
	if selected:
		spawn_selected()

func choose_spawn(cost : int, options : Array) -> int:
	# Go through options in random order
	options.shuffle()
	for option in options:
		# Choose the most expensive option within cost budget
		if option.cost <= cost and (selected == null or option.cost > selected.cost):
			# Skip if missing required tag
			if tags_allowed.size() > 0:
				var skip := true
				for tag in tags_allowed:
					if option.tags.has(tag):
						skip = false
						break
				if skip:
					continue
					
			selected = option
			
	# Return final choice point value
	if selected == null:
		return 0
		
	return selected.cost

func spawn_selected():
	spawn(load(selected.scene))
	
func spawn(scene : PackedScene):
	# Create instance
	var spawned = scene.instantiate()
	# Add to current scene
	get_tree().current_scene.call_deferred("add_child", spawned)
	# Move to spawn point
	spawned.global_position = global_position
