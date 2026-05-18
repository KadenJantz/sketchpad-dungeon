extends Resource

class_name LineAttack

@export var points: Array[Vector2]
@export_flags_2d_physics var collision_mask

# To be accessed by other modifiers
var last_hit_pos:Vector2
var last_hit_target
var last_hit_actor
var last_item

var enabled = false

var _ray_casts: Array[RayCast2D]

func physics_process(caller, item):
	if !enabled:
		return
		
	_deal_damage(caller, item)

func start_use(caller, item):
	# Mark enabled
	enabled = true
	
	# Check for attack
	_set_up(caller, item)

func finished_use(_caller, _item):
	# Mark disabled
	enabled = false
	
	# Remove ray casts
	for ray_cast in _ray_casts:
		ray_cast.queue_free()
		
	# Ensure the list is clear
	_ray_casts.clear()

func _set_up(caller, item):
	# Set up ray casts
	for i in range(points.size() - 1):
		_ray_casts.append(RayCast2D.new())
		caller.add_child(_ray_casts[i])
		
		# Correct scale
		_ray_casts[i].scale.x = 1/_ray_casts[i].global_scale.x
		_ray_casts[i].scale.y = 1/_ray_casts[i].global_scale.y
		
		_ray_casts[i].position = (points[i] * _ray_casts[i].scale).rotated(-deg_to_rad(item.held_rotation)) * item.max_range
		_ray_casts[i].target_position = points[i+1] * item.max_range
		_ray_casts[i].rotation = -deg_to_rad(item.held_rotation)
		_ray_casts[i].collision_mask = collision_mask
		
		# Allow for inside hit
		_ray_casts[i].hit_from_inside = true
		
func _deal_damage(caller, item):
	# Check all raycasts
	for ray_cast in _ray_casts:
		var hit = ray_cast.get_collider()
		
		# Go through all colliders hit
		while hit:
			# Do not hit again
			for ray in _ray_casts:
				ray.add_exception(hit)
				
			# Alert other modifiers
			last_hit_pos = ray_cast.get_collision_point()
			last_hit_target = hit
			last_hit_actor = caller
			last_item = item
			
			# Find actual actor in tree
			while !(last_hit_actor is CharacterBody2D):
				# Give up at top
				if last_hit_actor.get_parent() == null:
					last_hit_actor = caller
					break
					
				# Go up one
				last_hit_actor = last_hit_actor.get_parent()
				
			item.call_modifier_method("on_hit", self)
				
			# Calculate damage
			var damage = item.damage
			if is_last_hit_a_crit():
				damage = item.get_critical()
				
			# If object can be damaged, deal damage
			if hit.has_method("take_damage"):
				hit.call("take_damage", damage, self)
				
			# Try to get next hit
			ray_cast.force_raycast_update()
			hit = ray_cast.get_collider()

func is_last_hit_a_crit() -> bool:
	# Check class types
	if !(last_hit_actor is CharacterBody2D and last_item is WeaponStats):
		return false
	
	# Crits must deal more damage
	if last_item.crit_mult == 1:
		return false
	
	# Crits are mid-air
	if last_hit_actor.can_jump:
		return false
		
	# All checks passed; it is a crit
	return true
