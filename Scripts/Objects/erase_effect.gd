extends Node

@export var offset : Vector2
@export var rotation_offset = 0.0
@export var bounds = Vector2.ONE
@export var particle_scale = 1.0

var _effect : Node2D

const PATH = "res://Scenes/Particles/Effects/erase_mask.tscn"

func start():
	# Instantiate effect
	_effect = load(PATH).instantiate()
	get_parent().add_sibling(_effect)
	
	var parent := get_parent() as Node2D
	
	# Copy tranform over
	_effect.position = parent.position + offset
	_effect.rotation = parent.rotation + rotation_offset
	_effect.scale = parent.scale

	# Rechild parent to the effect
	parent.get_parent().remove_child(parent)
	_effect.add_child(parent)
	_effect.move_child(parent, 0)
	
	# Reset parent transform
	parent.position = -offset / abs(_effect.scale)
	parent.rotation = 0
	parent.scale = Vector2.ONE
	
	# Adjust layers
	_effect.z_index = parent.z_index
	parent.z_index = 0
	
	# Adjust particle spawner
	var particles := _effect.get_node("CPUParticles2D") as CPUParticles2D
	var max_scale = particles.scale_amount_max
	particles.scale_amount_min *= particle_scale / particles.global_scale.x
	particles.scale_amount_max = max_scale * particle_scale / particles.global_scale.x
	
	particles.emission_rect_extents *= bounds * particles.global_scale

func delete_after_delay(delay : float = 1.0):
	await get_tree().create_timer(delay).timeout
	
	_effect.queue_free()
