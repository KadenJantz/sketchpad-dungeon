extends BossState

class_name BossStateField

@export var field : PackedScene

@export var field_start_ref : NodePath
@export var field_duration : float
@export var field_offset : Vector2
@export var target_rotate : bool

@export var affected_groups : Array[String]
@export var unaffected_groups : Array[String]
@export var self_exception := true

var field_start : Node2D

func Enter(source : Node2D) -> void:
	super(source)
	
	# A new spell field spawns!
	var spawned : Node2D = field.instantiate()
	
	if not spawned is SpellField:
		push_warning(source.name + " is trying to spawn a spell field that is improperly assigned!")
		return
	
	# Duration may need to be adjusted
	if field_duration > 0:
		spawned.duration = field_duration;
	
	# Adjust other variables
	spawned.affected_groups.append_array(affected_groups);
	spawned.unaffected_groups.append_array(affected_groups);
	if self_exception:
		spawned.exceptions.append(source)
	if "source" in spawned:
		spawned.source = source
		
	# Bring into scene
	source.add_child(spawned)
		
	# Ensure start point is assigned
	if field_start == null:
		# Try path
		if not field_start_ref.is_empty():
			field_start = source.get_node(field_start_ref)
			
		# Default to source
		if field_start == null:
			field_start = source
		
	# Set up transform
	if target_rotate and source.target:
		var target : CollisionObject2D = source.target
		var target_pos := target.to_global(target.shape_owner_get_shape(0, 0).get_rect().position)
		
		# Calculate angle to target
		var dir : Vector2 = target_pos - field_start.global_position
		var angle := atan2(dir.y, dir.x)
		
		# Adjust tranfrom rotated by angle
		spawned.position = source.to_local(field_start.global_position) + field_offset.rotated(angle)
		spawned.rotate(angle)
	else:
		spawned.position = field_offset
