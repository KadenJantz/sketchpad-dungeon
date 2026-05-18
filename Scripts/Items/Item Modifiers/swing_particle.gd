extends Resource

class_name SwingParticle

@export var points: Array[Vector2]
@export var swing_particle:PackedScene
@export_range(0, 1) var color_overlay_amount:float

var current_particles: Array[Node2D]

func start_use(caller, item):
	# Create particles
	for point in points:
		var current_particle = swing_particle.instantiate()
		current_particle.position = (point * item.max_range / caller.global_scale).rotated(-deg_to_rad(item.held_rotation))
		
		# Spawn particle
		caller.add_child(current_particle)
		
		# Select child if necessary
		if not current_particle is CPUParticles2D:
			current_particle = current_particle.get_child(0)
		
		# Change particle color
		if color_overlay_amount > 0 and item.color:
			current_particle.modulate = Color.WHITE - (Color.WHITE - item.color) * color_overlay_amount
			
		# Add to list
		current_particles.append(current_particle)
	
func finished_use(caller, _item):
	for particle in current_particles:
		particle.emitting = false
	
		_wait_to_destroy(caller, particle)
	
func _wait_to_destroy(caller, particle):
	await particle.finished
	
	if particle.parent == caller:
		particle.queue_free()
	else:
		particle.parent.queue_free()
		
	current_particles.erase(particle)
