extends CPUParticles2D

@export var delay = .1

var extra_particles : Array[CPUParticles2D]

var _shader_color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Make sure particle is one shot
	one_shot = true

func change_shader_color(new_color:Color):
	_shader_color = new_color

func spawn_particle(spawn_amount = 1):
	# First one is always this
	if !emitting:
		emitting = true
		spawn_amount -= 1
		
		if _shader_color != null:
			material.set_shader_parameter("color", _shader_color)
	
	# Add additional ones as needed
	if spawn_amount > 0:
		var new_particle = duplicate()
		add_child(new_particle)
		extra_particles.append(new_particle)
		
		if _shader_color != null:
			new_particle.material = new_particle.material.duplicate()
			new_particle.material.set_shader_parameter("color", _shader_color)
		
		# Make transform be copied
		new_particle.rotation = 0
		new_particle.position = Vector2.ZERO
		new_particle.scale = Vector2.ONE
		
		spawn_amount -= 1
		
		# If it is still not spawned, call this function recursively after a delay
		if spawn_amount > 0:
			await get_tree().create_timer(delay).timeout
			spawn_particle(spawn_amount)

func _process(_delta: float) -> void:
	# Clean up unneeded particles
	if !extra_particles.is_empty():
		for i in range(extra_particles.size() - 1, -1, -1):
			var particle = extra_particles[i]
			
			if particle and !particle.emitting:
				particle.queue_free()
				extra_particles.remove_at(i)
