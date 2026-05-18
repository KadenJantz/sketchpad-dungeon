extends Resource

class_name HitParticle

@export var hit_particle:PackedScene
@export_range(0, 1) var color_overlay_amount:float

func on_hit(caller, item):
	# Create particle
	var particle = hit_particle.instantiate()
	particle.position = caller.last_hit_pos
	
	# Change particle color
	if color_overlay_amount > 0 and item.color:
		particle.modulate = item.color * color_overlay_amount
	
	# Spawn particle
	caller.last_hit_target.get_tree().root.add_child(particle)
	
	# Destroy particle later
	_wait_to_destroy(particle)
	
func _wait_to_destroy(particle):
	particle.emitting = true
	
	await particle.finished
	
	particle.queue_free()
