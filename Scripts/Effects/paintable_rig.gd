extends Node2D

@export var reverse = true
@export var mask_amount = 1.0;

var _sprites : Array[Sprite2D]
var _stages : Dictionary

var _stage : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get all sprites
	var sprites := find_children("*", "Sprite2D")
	
	for sprite : Sprite2D in sprites:
		# Skip empty sprites
		if sprite.texture == null:
			continue
		
		_sprites.append(sprite)
		
func set_stage(new_stage:int):
	_stage = new_stage
	
	clear_before(new_stage)

func clear_before(stage:int):
	# Clear any stage of a lesser number
	if _stages.keys().size() > 1:
		for i in _stages.keys():
			if i < stage == reverse:
				# Get rid of it!
				clear(i)

func clear_all():
	# Clear each stage one by one
	for stage in _stages.keys():
		clear(stage)
		
func clear(stage : int):
	for sprite in _stages[stage]:
		# Remove contents
		_stages[stage].erase(sprite)
		sprite.queue_free()
			
	# Remove stage entry
	_stages.erase(stage)

@warning_ignore("unused_parameter")
func paint_from_damage(direction:Vector2, attacker, receptient):
	# Only works if damage has an applicable source
	if "last_hit_pos" in attacker and "paint_effect" in attacker:
		var color = null
		
		if attacker.owner.material != null and attacker.owner.material.get_shader_parameter("color") != null:
			color = attacker.owner.material.get_shader_parameter("color")
			
		elif attacker.owner.modulate != Color.WHITE:
			color = attacker.owner.modulate
		
		add_paint_at(attacker.last_hit_pos, attacker.paint_effect.resource_path, color, direction.angle())

func add_paint_at(global_pos:Vector2, paint_effect, color = null, angle := 0.0):
	# Get info for paint
	var temp_paint = load(paint_effect).instantiate()
	var paint_size : Vector2 = temp_paint.texture.get_size() * temp_paint.scale
	var global_paint_size : Vector2 = paint_size
	var paint_rotation : float = temp_paint.rotation + angle
	temp_paint.queue_free()
	
	for sprite in _sprites:
		# Texture pixel counts
		var mask_size : Vector2 = sprite.texture.get_size() * mask_amount
		
		# Only continue if there is overlap
		if !Utility.do_rects_overlap_transform(global_pos, sprite.global_position, global_paint_size  * sprite.global_scale, 
		mask_size * sprite.global_scale, paint_rotation, sprite.rotation):
			# Skip this one, as it does not overlap
			continue
		
		var paint = load(paint_effect).instantiate()
		
		var saved_rotation = paint.global_rotation + angle
		
		# Add as child while preserving transform
		sprite.add_child(paint)
		paint.global_position = global_pos
		paint.global_rotation = saved_rotation
		
		var mask_rotation = -paint.rotation
		
		if sign(sprite.global_scale.x) != sign(sprite.global_scale.y):
			paint.scale.y *= -1
			mask_rotation *= -1
		
		# Assign texture as mask
		paint.material.set_shader_parameter("mask_texture", sprite.texture)
		
		# Used to set up mask
		var mask_scale = mask_size.x/paint_size.x
		var mask_ratio = mask_size.y/mask_size.x
		var mask_ratio_sprite = paint_size.x/paint_size.y
		
		# Calculate offset
		var offset = paint.position.rotated(-paint.rotation)/paint_size
			
		# Assign parameters to mask based on scale and ratio
		paint.material.set_shader_parameter("rect_size", mask_scale)
		paint.material.set_shader_parameter("ratio_height", mask_ratio)
		paint.material.set_shader_parameter("ratio_height_sprite", mask_ratio_sprite)
		paint.material.set_shader_parameter("angle", mask_rotation)
		paint.material.set_shader_parameter("location_x", ((1-mask_scale)/2) - offset.x)
		paint.material.set_shader_parameter("location_y", (1-mask_size.y/paint_size.y)/2 - (offset.y * sign(paint.scale.y)))
		
		# Set color
		if color != null:
			color.a = paint.modulate.a
			paint.modulate = color
		
		_add_to_stage(_stage, paint)

func _add_to_stage(stage:int, object):
	var contents = _get_stage_contents(stage)
	contents.append(object)
	_set_stage_contents(stage, contents)

func _get_stage_contents(stage:int) -> Array:
	if _stages.has(stage):
		return _stages[stage]
		
	return []

func _set_stage_contents(stage:int, contents:Array):
	_stages[stage] = contents
