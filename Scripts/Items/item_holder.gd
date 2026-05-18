extends Sprite2D

class_name ItemHolder

signal done_using

@export var hand_speed = 2.0
@export var front_hand: Node
@export var back_hand: Node
@export var item_held: ItemStats: set = _set_item_held

var base_rotation = 0
var base_offset: Vector2
var offsets_over_time: Array

var front_hand_goal_rot: float
var front_hand_goal_pos: Vector2
var back_hand_goal_pos: Vector2

var on_cooldown = false # Tracks if item is currently unable to be used again
var using = false # Tracks if item is being held out (in use)

var _front_hand_default
var _back_hand_default

var _item_held_delayed: ItemStats # Stores item when the item_held is still in use

func _ready():
	if front_hand:
		_front_hand_default = front_hand.position
	
	if back_hand:
		_back_hand_default = back_hand.position
	
func _process(_delta):
	# Finish offsets over time
	for i in range(offsets_over_time.size() - 1, -1, -1):
		var timed_offset = offsets_over_time[i]
		
		# Incrementally move closer to final offset
		if _delta < timed_offset[1]:
			apply_offset_change(timed_offset[0] * _delta)
			timed_offset[1] -= _delta
			
		# Last movement only goes as much as needed
		else:
			apply_offset_change(timed_offset[0] * timed_offset[1])
			offsets_over_time.remove_at(i)
	
	# Move towards goals
	if front_hand:
		# Get held item speed
		var held_speed = hand_speed
		# Attack rate increases speed for attacks
		if item_held and on_cooldown:
			held_speed *= item_held.rate
		
		# Move front hand
		front_hand.position = lerp(front_hand.position, front_hand_goal_pos + base_offset, _delta * held_speed)
		
		# Align back hand as well
		if back_hand:
			back_hand.position = lerp(back_hand.position, back_hand_goal_pos + base_offset, _delta * held_speed)
		
		# Calculate parent for rotation
		var parent_rot = get_parent().global_rotation
		
		# Compensate for parent's mirroring
		if global_scale.y < 0:
			parent_rot = PI - parent_rot
		
		var goal_rot = front_hand_goal_rot
		# Use effective angle if back hand is avaliable
		if back_hand:
			goal_rot = (back_hand.position - front_hand.position).angle()
			
			# Account for back hand being lower
			if item_held and item_held.length < 0:
				goal_rot += PI
		
		# Rotate item
		rotation = goal_rot + base_rotation - parent_rot
		
func _physics_process(_delta):
	if item_held:
		item_held.call_modifier_method("physics_process", self)

func set_hand_goals(hand_pos:Vector2, hand_rot:float, length:float):
	# Set the front hand
	front_hand_goal_pos = hand_pos
	# Set the rotation of item in first hand
	front_hand_goal_rot = deg_to_rad(hand_rot)
	# Set the back hand based on the rotation
	back_hand_goal_pos = hand_pos + (Vector2.RIGHT.rotated(front_hand_goal_rot) * length)
	
func play_use_anim(direction:float):
	# Return if missing any necessary elements
	if !item_held or !item_held.use_anim or !front_hand:
		return
		
	# Return if item is in use
	if on_cooldown:
		return
	
	var adjusted_dir = null
	if !item_held.directions.is_empty():
		for dir_option in item_held.directions:
			var dir_rad_option = deg_to_rad(dir_option)
			
			# If dir option is closer than previous option, go with that
			if adjusted_dir == null or Utility.angle_diff(dir_rad_option, direction) < Utility.angle_diff(adjusted_dir, direction):
				adjusted_dir = dir_rad_option
				
	else:
		# No need for adjustment
		adjusted_dir = direction
		
	# Initial use
	if !using:
		# Call item modifiers
		item_held.call_modifier_method("start_use", self)
		
		# Enable using, so any changes just change direction
		using = true
		
		# Prevent overlapping uses
		on_cooldown = true
		
		# Set delayed item to delayed to see if it changes
		_item_held_delayed = item_held
		
				
		# Set for each anim
		for i in range(item_held.use_anim.length()):
			var pos = item_held.use_anim.get_position(i, adjusted_dir)-front_hand.get_parent().position
			var rot = item_held.use_anim.get_rotation(i, adjusted_dir)
			
			set_hand_goals(pos, rot, item_held.length)
			
			await get_tree().create_timer(item_held.use_anim.get_time(i)/item_held.rate).timeout
			
		# Call item modifiers
		item_held.call_modifier_method("finished_use", self)
		
		# Allow more uses
		on_cooldown = false
		
		# Await done using to exit
		await done_using
		
		# Call item modifiers
		item_held.call_modifier_method("released_use", self)
		
		# Mark as no longer in use		
		using = false
		
		# Refresh held item if it changed
		if item_held != _item_held_delayed:
			item_held = _item_held_delayed
			
		# Otherwise, reset to default hold position
		else:
			set_hand_goals(item_held.front_hand_pos, item_held.front_hand_rot, item_held.length)
			
		
	# All uses while still in use
	else:
		# Only use last one
		var i = item_held.use_anim.length() - 1
		
		var pos = item_held.use_anim.get_position(i, adjusted_dir)-front_hand.get_parent().position
		var rot = item_held.use_anim.get_rotation(i, adjusted_dir)
		
		set_hand_goals(pos, rot, item_held.length)

func apply_offset_change(change : Vector2):
	base_offset += change
	front_hand.position += change
	back_hand.position += change
	
func apply_offset_over_time(change : Vector2, time : float):
	offsets_over_time.push_back([change/time, time])

func _set_item_held(new_item_held = null):
	# If using previous item, stop
	done_using.emit()
	
	# When item on cooldown, just set the item with a delay
	if on_cooldown:
		_item_held_delayed = new_item_held
		
		return
	
	if new_item_held == null:
		texture = null
		item_held = null
		if front_hand:
			front_hand_goal_pos = _front_hand_default
			back_hand_goal_pos = _back_hand_default
		return
	
	# Set item info
	texture = new_item_held.image
	offset = new_item_held.held_offset
	rotation = deg_to_rad(new_item_held.front_hand_rot + new_item_held.held_rotation)
	
	# Set base roation based on set rotation from item
	base_rotation = deg_to_rad(new_item_held.held_rotation)
	
	# Set item color
	if new_item_held.color:
		# Change item
		self.material.set_shader_parameter("color", new_item_held.color)
		
	#Prepare hand anims
	if front_hand:
		set_hand_goals(new_item_held.front_hand_pos, new_item_held.front_hand_rot, new_item_held.length)
		
	item_held = new_item_held
