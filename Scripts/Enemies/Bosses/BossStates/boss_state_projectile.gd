extends BossState

class_name BossStateProjectile

@export var projectile : PackedScene
@export var spawnpoint : NodePath
@export var damage := 1.0
@export var follow_target : bool

var spawn : Node2D

func Enter(source : Node2D) -> void:
	super(source)
	
	# Ensure spawn point is assigned
	if spawn == null:
		# Try path
		if not spawnpoint.is_empty():
			spawn = source.get_node(spawnpoint)
		
		# Default to source
		if spawn == null:
			spawn = source
			
	var spawned := projectile.instantiate()
	
	source.add_child(spawned)
	spawned.global_position = spawn.global_position
	
	if spawned is Projectile:
		# Adjust damage
		spawned.damage = damage
		
		# Set up targeting
		if source.target:
			var target : CollisionObject2D = source.target
			
			if follow_target:
				spawned.dyn_target = target.shape_owner_get_owner(0)
				spawned.target = spawned.dyn_target.global_position
			else:
				spawned.target = target.to_global(target.shape_owner_get_shape(0, 0).get_rect().position)
				
			spawned.refresh_rotation()
